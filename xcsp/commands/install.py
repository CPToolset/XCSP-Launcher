"""Solver installation manager for XCSP Launcher.

This module handles the full process of installing a solver from a repository:
cloning the repository, detecting or resolving configuration files, verifying
build requirements, building the solver, and placing binaries at the correct locations.
"""

import enum
import os
import shutil
from abc import ABC, abstractmethod
from pathlib import Path
import yaml
from git import Repo
from loguru import logger
from timeit import default_timer as timer

from xcsp.builder.build import AutoBuildStrategy, ManualBuildStrategy
from xcsp.builder.check import check_available_builder_for_language, MAP_FILE_LANGUAGE, MAP_LANGUAGE_FILES, MAP_BUILDER
from xcsp.solver.resolver import resolve_config
from xcsp.utils.paths import get_solver_install_dir, ChangeDirectory, get_solver_bin_dir
from xcsp.utils.log import unknown_command


class RepoSource(enum.Enum):
    """Enumeration of supported repository hosting services."""
    GITHUB = "github.com"
    GITLAB = "gitlab.com"


class ConfigStrategy(ABC):
    """Abstract base class representing a strategy for handling solver configurations."""

    def __init__(self, solver_path: Path, repo):
        self._language = None
        self._builder_file = None
        self._solver_path = solver_path
        self._repo = repo

    def check(self):
        """Check if a valid builder is available for the detected language."""
        return check_available_builder_for_language(self.language())

    def language(self):
        """Return the programming language of the solver."""
        return self._language

    def builder_file(self) -> Path:
        """Return the main build configuration file."""
        return self._builder_file

    @abstractmethod
    def versions(self):
        """Yield information about available versions of the solver."""
        pass

    @abstractmethod
    def detect_language(self):
        """Detect the programming language of the solver based on available files."""
        pass


class NoConfigFileStrategy(ConfigStrategy):
    """Strategy used when no solver configuration file is provided."""

    def versions(self):
        """Yield a single version 'latest' based on the current commit hash."""
        yield {"version": "latest", "git_tag": self._repo.head.object.hexsha}

    def detect_language(self):
        """Attempt to detect the language by scanning known build files."""
        list_files = set(os.listdir(self._solver_path))
        for file in MAP_FILE_LANGUAGE.keys():
            if file in list_files:
                self._language = MAP_FILE_LANGUAGE[file]
                self._builder_file = Path(self._solver_path, file)
                logger.success(f"Detected language using builder file '{file}': {self.language()}")
                return
        raise ValueError("Unable to detect the project language automatically.")


class ConfigFileStrategy(ConfigStrategy):
    """Strategy used when a solver configuration file is available."""

    def __init__(self, solver_path: Path, config):
        super().__init__(solver_path, None)
        self._config = config

    def language(self):
        """Return the programming language from the configuration."""
        return self._config["language"]

    def detect_language(self):
        """Detect the language based on configuration and project structure."""
        logger.success(f"Language provided by configuration file: {self.language()}")
        l = self.language()
        files = MAP_LANGUAGE_FILES[l]
        logger.debug(f"Looking for one of: {', '.join(files)}")

        list_files = set(os.listdir(self._solver_path))
        for f in files:
            if f in list_files:
                self._builder_file = Path(self._solver_path, f)
                return

    def versions(self):
        """Yield all versions specified in the configuration."""
        for v in self._config["versions"]:
            yield v


class Installer:
    """Main class responsible for installing a solver from a repository."""

    def __init__(self, url: str, solver_name: str, id: str):
        self._url = url
        self._solver = solver_name
        self._id = id
        self._path_solver = None
        self._start_time = timer()
        self._repo = None
        self._config = None
        self._config_strategy = None
        self._mode_build_strategy = None

    def _init(self):
        """Initialize the solver installation directory."""
        self._path_solver = Path(get_solver_install_dir()) / self._id
        os.makedirs(self._path_solver, exist_ok=False)

    def _clone(self):
        """Clone the solver repository."""
        logger.info(f"Cloning the solver from {self._url} into {self._path_solver}")
        self._repo = Repo.clone_from(self._url, self._path_solver)
        logger.info(f"Repository cloned in {timer() - self._start_time:.2f} seconds.")

    def _resolve_config(self):
        """Resolve and load the solver configuration if available."""
        config_file = resolve_config(self._path_solver, self._solver)

        if config_file is None:
            self._config_strategy = NoConfigFileStrategy(self._path_solver, self._repo)
            self._mode_build_strategy = AutoBuildStrategy(self._path_solver, self._config_strategy)
            return

        with open(config_file, "r") as f:
            self._config = yaml.safe_load(f)
            self._config_strategy = ConfigFileStrategy(self._path_solver, self._config)
            if self._config.get("mode", "manual") == "auto":
                self._mode_build_strategy = AutoBuildStrategy(self._path_solver, self._config_strategy)
            else:
                self._mode_build_strategy = ManualBuildStrategy(self._path_solver, self._config_strategy, self._config)

    def _check(self):
        """Check if the required build tools are available."""
        if not self._config_strategy.check():
            language = self._config_strategy.language()
            logger.error(f"None of the builders are available for language '{language}': {', '.join(MAP_BUILDER.get(language))}")
            raise ValueError(
                f"No available builders for the detected language '{language}'.")

    def install(self):
        """Main method to install the solver."""
        self._init()
        self._clone()
        self._resolve_config()
        self._check()

        with ChangeDirectory(self._path_solver):
            for v in self._config_strategy.versions():
                logger.info(f"Checking out version '{v['git_tag']}'")
                self._repo.git.checkout(v["git_tag"])

                if not self._mode_build_strategy.build():
                    logger.error(f"Build failed for version '{v['version']}'. Installation aborted.")
                    break

                bin_dir = get_solver_bin_dir(self._solver, v['version'])
                os.makedirs(bin_dir, exist_ok=True)

                if v.get("executable") is None:
                    logger.warning(
                        f"Version '{v['version']}' was built, but no executable was specified. "
                        f"Please manually copy your binaries into {bin_dir}.")
                    continue

                result_path = shutil.copy(os.path.join(self._path_solver, v["executable"]), bin_dir)
                logger.success(f"Executable for version '{v['version']}' successfully copied to {result_path}.")


def resolve_url(repo, source):
    """Construct the full URL from a repo namespace and source."""
    return "https://" + source.value + "/" + repo


def fill_parser(parser):
    """Add the 'install' subcommand to the parser."""
    parser_install = parser.add_parser("install", aliases=["i"],
                                       help="Subcommand to install a solver from a repository.")
    parser_install.add_argument("--id", help="Unique ID for the solver.", type=str, required=True)
    parser_install.add_argument("--name", help="Human-readable name of the solver.", type=str, required=True)
    parser_install.add_argument("--url", help="Direct URL to the repository (alternative to --repo).", required=False)
    parser_install.add_argument("--repo", help="Repository in the form 'namespace/repo' (alternative to --url).", required=False)
    parser_install.add_argument("--source", help="Hosting service for the repository.", choices=[e for e in RepoSource], default=RepoSource.GITHUB, type=RepoSource)


def install(args):
    """Execute the installation process based on parsed arguments."""
    if args.url is None and args.repo is None:
        raise ValueError("Both --url and --repo cannot be None simultaneously.")

    url = args.url
    if url is None:
        url = resolve_url(args.repo, args.source)

    installer = Installer(url, args.name, args.id)
    installer.install()


MAP_COMMAND = {
    "install": install,
}


def manage_command(args):
    """Dispatch and manage subcommands for the XCSP launcher binary.

    Args:
        args (dict): Parsed command-line arguments.
    """
    subcommand = args['subcommand']
    MAP_COMMAND.get(subcommand, unknown_command)(args)
