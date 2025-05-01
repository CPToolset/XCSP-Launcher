# 📄 Solver Configuration


## Solver Configuration File Specification

This section describes the structure of *solver configuraiton* files used by **XCSP Launcher** to register, build, and run solvers.

The extension of the file can be one of these extensions: 

- `.xsc.yaml` 
- `.xsc` 
- `.solver.yaml` 
- `.solver`
- `.xsc.yml` 
- `.solver.yml`

---

### 🧩 General Information

| Field        | Type    | Required | Description                                                                 |
|--------------|---------|----------|-----------------------------------------------------------------------------|
| `name`       | string  | ✅ Yes   | Human-readable name of the solver.                                          |
| `id`         | string  | ✅ Yes   | Unique identifier (Java-like package name recommended).                     |
| `description`| string  | ❌ No    | Short description of the solver.                                            |
| `git` | string | ⚠️ Yes (if path is not provided) | Git repository URL of the solver. Must not be used together with path. |
| `path` | string | ⚠️ Yes (if git is not provided) | Local path to a solver already available on disk. Must not be used together with git. |
| `language`   | string  | ✅ Yes   | Programming language (e.g., `java`, `cpp`, `rust`, `python`, etc.).         |
| `tags`       | string[]| ❌ No    | Tags like `cp`, `cop`, `integer`, `scheduling`...                           |
| `system`     | string or string[] | ✅ Yes | List of compatible OS (`Linux`, `Windows`, `macOS`) or `"all"`.             |

---

### 🛠️ Build Instructions

| Field                  | Type                | Required | Description                                                | Default |
|------------------------|---------------------|----------|------------------------------------------------------------|---------|
| `build.mode`           | string              | ✅ Yes   | Must be `"manual"` or `"auto"`.                            | -       |
| `build.build_command`  | string or string[]  | ⚠️ Yes if `manual` | Shell command(s) to compile the solver manually.        | -       |

---

### ⚙️ Command Line Execution

| Field                         | Type               | Required | Description                                                                                              | Default |
|-------------------------------|--------------------|----------|----------------------------------------------------------------------------------------------------------|---------|
| `command.prefix`              | string             | ❌ No    | Prefix like `{{java}} -jar`, `{{python}}`.                                                               | ""      |
| `command.template`            | string             | ✅ Yes   | Template string with placeholders like `{{executable}} {{instance}} {{options}}`.                        | -       |
| `command.always_include_options` | string          | ❌ No    | Options appended to every call.                                                            | ""      |
| `command.options.time`        | string or null     | ❌ No    | Option to specify timeout in seconds. Placeholder: `{{value}}` integer that represents the time in seconds.                                          | null    |
| `command.options.seed`        | string or null     | ❌ No    | Option to specify the random seed.  Placeholder: `{{value}}` integer that represents the seed                                                                    | null    |
| `command.options.all_solutions` | string or null   | ❌ No    | Option to enable enumeration of all solutions.                                                           | null    |
| `command.options.number_of_solutions` | string or null | ❌ No | Option to limit number of solutions. Placeholder: `{{value}}` integer that represents the maximum number of solution.                                           | null    |
| `command.options.verbosity`   | string or null     | ❌ No    | Verbosity control. Placeholder: `{{value}}` an integer that represents the level.                                                                                     | null    |
| `command.options.print_intermediate_assignment` | string or null | ❌ No | Option to show intermediate assignment.                                                        | null    |

---

### 🗃️ Versions Management

| Field               | Type     | Required | Description                                                          |
|---------------------|----------|----------|----------------------------------------------------------------------|
| `versions`          | object[] | ✅ Yes   | List of solver versions to support.                                 |
| `version.version`   | string   | ✅ Yes   | Version label (e.g., `"2.4"`, `"latest"`, `"dev"`).                 |
| `version.alias`     | string[] | ❌ No    | Optional list of aliases.                                           |
| `version.executable`| string   | ✅ Yes   | Path to executable relative to the root of the cloned repo.         |
| `version.git_tag`   | string   | ✅ Yes   | Git tag or commit hash used to fetch this version.                  |

---

### 📥 Output Parsing

This is a special section that corresponds to the [`data` part](https://metrics.readthedocs.io/en/latest/scalpel-config.html#description-of-the-data-to-extract) of the `metrics-scalpel` configuration file. 

| Field           | Type       | Required | Description                                                                 |
|------------------|------------|----------|-----------------------------------------------------------------------------|
| `parsing.data`   | object[]   | ❌ No   | Extraction rules to interpret the solver output.                           |


---

### 🔁 Available Placeholders

You can use the following placeholders in `command.template` and `build.build_command`:

| Placeholder        | Description                                                       |
|--------------------|-------------------------------------------------------------------|
| `{{executable}}`   | Path to the compiled executable.                                  |
| `{{instance}}`     | Path to the XCSP3 instance.                                       |
| `{{options}}`      | All generated options passed to the solver.                       |
| `{{java}}`         | Full path to the system Java binary (`/usr/bin/java`, etc.).      |
| `{{python}}`       | Full path to the Python interpreter.                              |
| `{{cmake}}`        | Full path to cmake, usually resolved automatically.               |
| `{{SOLVER_DIR}}`   | Absolute path to the solver source directory.                     |

---

### 📌 Notes

- Fields like `command.options` support `null` when the option is not applicable.
- If `system` is omitted or set to `"all"`, the solver is assumed compatible with all operating systems.
- It is strongly recommended to define at least one version with alias `"latest"`.

--- 

## Configuration file discovery

