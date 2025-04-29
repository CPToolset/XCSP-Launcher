import enum
import json
import shlex
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List

import psutil
from loguru import logger

from xcsp.solver.cache import CACHE

ANSWER_PREFIX = "s" + chr(32)
OBJECTIVE_PREFIX = "o" + chr(32)
SOLUTION_PREFIX = "v" + chr(32)


class ResultStatusEnum(enum.Enum):
    SATISFIABLE = "SATISFIABLE"
    UNSATISFIABLE = "UNSATISFIABLE"
    UNKNOWN = "UNKNOWN"
    OPTIMUM = "OPTIMUM FOUND"


class Solver:

    def __init__(self, name, id_solver, version, command_line, options, alias=None):
        self._prefix = None
        self._stderr = sys.stderr
        self._stdout = sys.stdout
        self._name = name
        self._id = id_solver
        self._version = version
        self._command_line = command_line
        self._options = options
        self._args = []
        self._alias = alias if alias is not None else []
        self._solutions = None
        self._time_limit = None
        self._print_intermediate_assignment = False
        self._json_output = False

    @property
    def name(self):
        return self._name

    @property
    def id(self):
        return self._id

    @property
    def version(self):
        return self._version

    @property
    def alias(self):
        return self._alias

    @property
    def cmd(self):
        return self._command_line

    def set_time_limit(self, time_limit: int | None):
        if time_limit is not None:
            placeholder_time = self._options["time"]
            self._args.append(placeholder_time.replace("{{value}}", str(time_limit)))
            self._time_limit = time_limit

    def set_seed(self, seed: int | None):
        if seed is not None:
            placeholder_seed = self._options["seed"]
            self._args.append(placeholder_seed.replace("{{value}}", str(seed)))

    def all_solutions(self, activate: bool):
        if activate:
            self._args.append(self._options["all_solutions"])

    def set_limit_number_of_solutions(self, limit: int | None):
        if limit is not None and limit>0:
            placeholder_limit = self._options["number_of_solutions"]
            self._args.append(placeholder_limit.replace("{{value}}", str(limit)))

    def set_collect_intermediate_solutions(self, activate: bool):
        if activate:
            self._print_intermediate_assignment = activate
            self._args.append(self._options["print_intermediate_assignment"])

    def add_complementary_options(self, options):
        self._args.extend(options)

    def set_output(self, output):
        self._stdout = open(output,"w") if output!="stdout" else sys.stdout

    def set_error(self, error):
        self._stderr = open(error,"w") if error!="stderr" else sys.stderr

    def set_prefix(self, prefix):
        self._prefix = prefix

    def set_json_output(self,activate):
        self._json_output = activate

    def solve(self, instance_path, keep_solver_output=False):
        """
        Launch and monitor the solver on the given instance.

        Args:
            instance_path (str | Path): Path to the instance file.
            keep_solver_output (bool): Whether to display the solver's stdout live.

        Returns:
            List[Solution]: Parsed solutions found by the solver.
        """
        command = self._command_line
        for opt in self._args:
            command += f" {opt}"
        command = command.replace("{{instance}}", str(instance_path))

        logger.info(f"Launching solver: {command}")

        # Launch process
        process = psutil.Popen(
            shlex.split(command),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        wall_start = time.time()
        cpu_start = psutil.cpu_times()

        bounds = []
        assignments = []
        status = ResultStatusEnum.UNKNOWN.value
        solution_timestamps = []

        try:
            for line in process.stdout:
                line = line.rstrip()

                current_wall = time.time()
                current_cpu = psutil.cpu_times()
                wall_clock_time = current_wall - wall_start
                cpu_time = (current_cpu.user - cpu_start.user) + (current_cpu.system - cpu_start.system)

                if line.startswith(ANSWER_PREFIX):
                    tokens = line.split()
                    if len(tokens) > 1:
                        status = ResultStatusEnum[tokens[1].replace(" ","_")]

                elif line.startswith(OBJECTIVE_PREFIX):
                    tokens = line.split()
                    if len(tokens) > 1:
                        try:
                            value = int(tokens[1])
                            bounds.append({"value": value, "wall_clock_time": wall_clock_time, "cpu_time": cpu_time})
                            if not self._json_output:
                                print(f"o {value}")
                        except ValueError:
                            pass

                elif line.startswith(SOLUTION_PREFIX):
                    assign = line[2:].strip()
                    assignments.append({"solution": assign, "wall_clock_time": wall_clock_time, "cpu_time": cpu_time})
                    if self._print_intermediate_assignment and not self._json_output:
                        print(f"v {assign}", file=sys.stdout)

                # If live output is enabled
                if keep_solver_output:
                    if self._prefix:
                        print(f"{self._prefix} {line}", file=self._stdout)
                    else:
                        print(line, file=self._stdout)

            process.wait()

        except Exception as e:
            logger.exception("An error occurred during solver execution")
            process.kill()
            raise e

        # Final times
        wall_end = time.time()
        cpu_end = psutil.cpu_times()

        final_wall_clock_time = wall_end - wall_start
        final_cpu_time = (cpu_end.user - cpu_start.user) + (cpu_end.system - cpu_start.system)
        # Build JSON
        self._solutions = {
            "status": status.value,
            "bounds": bounds,
            "assignments": assignments,
            "wall_clock_time": final_wall_clock_time,
            "cpu_time": final_cpu_time
        }
        if self._json_output:
            print(json.dumps(self._solutions, indent=2))
        else:
            print(f"s {status.value}")
        logger.info(f"Resolution completed successfully. Wall-clock time: {final_wall_clock_time:.2f}s | CPU time: {final_cpu_time:.2f}s")

        self._print_final_summary(status, bounds, assignments, final_wall_clock_time, final_cpu_time)

        return self._solutions
    @staticmethod
    def lookup(name: str) -> 'Solver':
        name_solver = name
        version_solver = 'latest'
        if '@' in name:
            split = name.split('@')
            name_solver = split[0]
            version_solver = split[1]
        solvers = Solver.available_solvers()
        alias_solvers = dict()
        for k, v in solvers.items():
            for a in v.alias:
                alias_solvers[f"{v.name}@{a}"] = v
        logger.debug(solvers)
        logger.debug(alias_solvers)
        key = f"{name_solver.upper()}@{version_solver}"
        if key not in solvers and key not in alias_solvers:
            raise ValueError(
                f"Impossible to found an installed solver with the name {name_solver} and the version {version_solver}")

        return solvers.get(key, alias_solvers.get(key))

    @staticmethod
    def available_solvers() -> Dict[str, 'Solver']:
        solvers = dict()
        for k, s in CACHE.items():
            for vv in s["versions"].keys():
                solvers[f"{s['name_solver']}@{vv}"] = (
                    Solver(s["name_solver"], s["id_solver"], vv, s["versions"][vv]['cmd'],
                           s["versions"][vv]['options'], s["versions"][vv].get('alias')))
        return solvers


    @staticmethod
    def create_from_cli(args):
        s = Solver.lookup(args.get("name"))
        s.set_seed(args.get("seed"))
        s.set_time_limit(args.get("timeout"))
        s.set_collect_intermediate_solutions(args.get("intermediate"))
        s.set_limit_number_of_solutions(args.get("num_solutions"))

        stdout = 'stdout' if args.get("stdout") == 'stdout' else Path(args.get('tmp_dir'))/args.get("stdout")
        stderr = 'stderr' if args.get("stderr") == 'stderr' else Path(args.get('tmp_dir'))/args.get("stderr")

        s.set_output(stdout)
        s.set_error(stderr)
        s.set_prefix(args.get("prefix"))
        s.set_json_output(args.get("json_output"))
        s.all_solutions(args.get("all_solutions"))
        return s

    def _print_final_summary(self, status, bounds, assignments, final_wall_clock_time, final_cpu_time):
        nb_solutions = max(len(assignments), len(bounds))
        nb_bounds = len(bounds)
        best_objective = None
        if nb_bounds > 0:
            best_objective = bounds[-1]["value"]  # Toujours prendre le dernier bound

        # Choix de l'icône selon le status
        emoji = "❓"
        status_upper = status.value.upper()

        if "SATISFIABLE" in status_upper:
            emoji = "✅"
        elif "UNSATISFIABLE" in status_upper:
            emoji = "❌"
        elif "UNKNOWN" in status_upper:
            emoji = "❓"
        elif "OPTIMUM" in status_upper:
            emoji = "🏆"
        else:
            emoji = "⚡"  # Pour tous les autres cas (ex: TIMEOUT, INTERRUPTED...)

        # Construction du résumé
        summary_parts = [
            f"{emoji} {status.value}",
            f"{nb_solutions} solutions" if nb_solutions > 0 else "No solutions",
        ]

        if best_objective is not None:
            summary_parts.append(f"Best objective: {best_objective}")

        summary_parts.append(f"Wall: {final_wall_clock_time:.2f}s")
        summary_parts.append(f"CPU: {final_cpu_time:.2f}s")

        logger.info(" | ".join(summary_parts))