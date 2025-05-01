# 🛠️ Solver Installation

Solvers can be installed using the `install` subcommand of `xcsp`.  
This provides multiple flexible ways to fetch, configure, and build solvers from configuration files or remote repositories.

```bash
xcsp install --help
```

```text
usage: xcsp install [-h] [--id ID] [--name NAME] [-c CONFIG] [--url URL]
                    [--repo REPO]
                    [--source {RepoSource.GITHUB,RepoSource.GITLAB}]
```

---

## 📦 Installation Methods

### 🔹 1. From a Configuration File

Use the `--config` (or `-c`) option to specify a local solver configuration file:

```bash
xcsp install --config ./solvers/ace.solver.yaml
```

This file must follow the [Solver Configuration Format](solver_configuration.md#solver-configuration-file-specification), describing how to fetch and build the solver.

---

### 🔹 2. From a Direct Git URL

Use the `--url` option to install from a remote Git repository.  
This method **requires** you to specify the solver's `--id` and `--name`:

```bash
xcsp install --url https://github.com/xcsp3team/ace --id fr.cril.xcsp.ace --name ACE
```

- If the repository contains a solver config file (e.g., `ace.solver.yaml`), it will be used automatically.
- If not, the launcher will attempt to find `<name>.solver.yaml` in its known search paths.
- If no configuration file is found, `xcsp-launcher` attempts to build the solver using a `builder` file. See [Solver Building](solver_building.md) for details. Note that in this case, it cannot automatically move the generated binaries to the solver's `bin` directory.

See [Configuration File Discovery](solver_configuration.md#configuration-file-discovery) for details.

---

### 🔹 3. From a GitHub/GitLab Repository

Use the `--repo` option for a shorthand reference to a repository:

```bash
xcsp install --repo xcsp3team/ace --id fr.cril.xcsp.ace --name ACE
```

By default, the repository is assumed to be hosted on GitHub.  
To use GitLab instead, add:

```bash
--source RepoSource.GITLAB
```

🔁 This method works just like `--url`, but is more concise.

---

## 🔧 Common Options

| Option        | Description                                                           |
|---------------|-----------------------------------------------------------------------|
| `--id`        | Unique solver ID (required for `--url` and `--repo`)                  |
| `--name`      | Human-readable name of the solver (required for `--url` and `--repo`) |
| `--url`       | Git URL to the solver repository                                      |
| `--repo`      | Git repo in the form `namespace/project`                              |
| `--source`    | Hosting provider (`RepoSource.GITHUB`, `RepoSource.GITLAB`)           |

---

✅ After installation, you can check installed solvers with:

```bash
xcsp solver --solvers
```

👉 Want to write your own solver configuration? See [Solver Configuration Format](solver.md#solver-configuration-file)
