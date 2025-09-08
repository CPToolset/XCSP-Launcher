# 📄 Solver Configuration

## Solver Configuration File Specification

This section describes the structure of *solver configuration* files used by **XCSP Launcher** to register, build, and run solvers.

Supported file extensions:

* `.xsc.yaml`
* `.xsc.yml`
* `.xsc`
* `.solver.yaml`
* `.solver.yml`
* `.solver`

> A JSON Schema for validating solver configuration files is available at:
> [https://github.com/crillab/metrics-solvers/blob/main/.solver.schema.json](https://github.com/crillab/metrics-solvers/blob/main/.solver.schema.json)

---

### 🧩 General Information

| Field         | Type                       | Required                        | Description                                                                    |
| ------------- | -------------------------- | ------------------------------- | ------------------------------------------------------------------------------ |
| `name`        | string                     | ✅ Yes                           | Human-readable name of the solver.                                             |
| `id`          | string                     | ✅ Yes                           | Unique identifier (Java-like package name recommended).                        |
| `description` | string                     | ❌ No                            | Short description of the solver.                                               |
| `website`     | string (URL)               | ❌ No                            | Official website for the solver.                                               |
| `git`         | string (URL)               | ⚠️ Yes (if `path` not provided) | Git repository URL. Cannot be used with `path`.                                |
| `path`        | string                     | ⚠️ Yes (if `git` not provided)  | Local path to an already available solver. Cannot be used with `git`.          |
| `language`    | string                     | ✅ Yes                           | Programming language (`java`, `cpp`, `rust`, `python`, etc.).                  |
| `tags`        | array of strings           | ❌ No                            | Tags such as `cp`, `cop`, `integer`, `scheduling`.                             |
| `system`      | string or array of strings | ❌ No                            | Compatible OS list (`Linux`, `Windows`, `macOS`) or `"all"`. Default: `"all"`. |

---

### 🛠️ Build Instructions

| Field                 | Type                 | Required                               | Description                                                         |
| --------------------- | -------------------- | -------------------------------------- | ------------------------------------------------------------------- |
| `build.mode`          | string               | ✅ Yes                                  | Either `"manual"` or `"auto"`.                                      |
| `build.default_steps` | array of objects     | ⚠️ Yes if `per_os` not provided        | List of generic build steps.                                        |
| `build.per_os`        | object (by platform) | ⚠️ Yes if `default_steps` not provided | OS-specific build steps or skip instructions.                       |
| `build.dependencies`  | array of objects     | ❌ No                                   | External dependencies (Git or archive) to download before building. |

#### 🔗 Dependencies Structure

Each dependency supports:

| Field | Type   | Required | Description                                                         |
| ----- | ------ | -------- | ------------------------------------------------------------------- |
| `git` | string | ❌ No     | Git repository URL.                                                 |
| `url` | string | ❌ No     | Direct download URL (e.g., zip, tar.gz).                            |
| `dir` | string | ✅ Yes    | Directory where the dependency is installed (relative or absolute). |

> Either `git` or `url` **must** be provided.

#### 🔨 Build Step Structure

Each step contains:

| Field | Type   | Required | Description                                                 |
| ----- | ------ | -------- | ----------------------------------------------------------- |
| `cmd` | string | ✅ Yes    | Command to execute. Templated and auto-split.               |
| `cwd` | string | ❌ No     | Working directory for the command. Defaults to solver root. |

#### 🔁 OS-specific Builds (`per_os`)

Each platform (`linux`, `windows`, `macos`) can contain:

* `skip: true` to disable build on that OS.
* `steps:` array of build steps (same format as `default_steps`).

---

### ⚙️ Command Line Execution

| Field                            | Type   | Required | Description                                              |
| -------------------------------- | ------ | -------- | -------------------------------------------------------- |
| `command.prefix`                 | string | ❌ No     | Command prefix (e.g., `{{java}} -jar`, `{{python}}`).    |
| `command.template`               | string | ✅ Yes    | Template like `{{executable}} {{instance}} {{options}}`. |
| `command.always_include_options` | string | ❌ No     | Always-appended options.                                 |
| `command.options`                | object | ❌ No     | Supported runtime options with placeholders.             |

#### 🧰 Supported `command.options` Fields:

Each is `string` (template) or `null`.

* `time`: Timeout option (`{{value}}` in seconds)
* `seed`: Seed specification
* `all_solutions`: Enumerate all solutions
* `number_of_solutions`: Max number of solutions (`{{value}}`)
* `verbosity`: Verbosity level (`{{value}}`)
* `print_intermediate_assignment`: Show assignments

---

### 🗃️ Versions Management

| Field                | Type   | Required                      | Description                                                                                                  |
| -------------------- | ------ | ----------------------------- |--------------------------------------------------------------------------------------------------------------|
| `versions`           | array  | ✅ Yes                         | List of supported versions.                                                                                  |
| `version.version`    | string | ✅ Yes                         | Version label (e.g., `2.4`, `dev`, `main`, `3.8#7`, `4.10.18`).                                              |
| `version.source`     | string | ❌ No                          | `"git"` or `"archive"`. Inferred if omitted.                                                                 |
| `version.git_tag`    | string | ⚠️ Yes if source is `git`     | Git tag or commit hash.                                                                                      |
| `version.urls`       | object | ⚠️ Yes if source is `archive` | Map of OS to download URLs.                                                                                  |
| `version.executable` | string | ✅ Yes                         | Relative path to the compiled executable.                                                                    |
| `version.alias`      | array  | ❌ No                          | Aliases like `"stable"`, `"latest"`, etc.                                                                    |
| `version.files`      | array  | ❌ No                          | Files to move after extraction (for example from source directory to bin directory). Each item: `{from, to}` |

---

### 📥 Output Parsing

| Field          | Type  | Required | Description                                                            |
| -------------- | ----- | -------- |------------------------------------------------------------------------|
| `parsing.data` | array | ❌ No     | List of log extraction rules (for compatibility with Metrics Scalpel). |

Each item supports:

* `file` (string): file name to parse
* `pattern` or `regex` (one required)
* `log-data` (optional): label
* `groups` (optional): either array of indexes, or named `bound_list`, `timestamp_list`

---

### 🧩 Placeholders

These can be used in `cmd`, `cwd`, `template`, and any string field:

| Placeholder      | Description                              |
|------------------|------------------------------------------|
| `{{solver_dir}}` | Absolute path to solver source directory |
| `{{bin_dir}}`    | Absolute path to solver bin directory    |
| `{{executable}}` | Compiled binary path                     |
| `{{instance}}`   | XCSP3 instance file path                 |
| `{{options}}`    | All generated options to be appended     |
| `{{java}}`       | Java binary path                         |
| `{{python}}`     | Python binary path                       |
| `{{cmake}}`      | CMake binary path                        |
| `{{bash}}`       | Bash binary path                         |

> Placeholders are case-insensitive (`{{BASH}}`, `{{BaSh}}` work too).

---

### 📌 Notes

* You should define a version with alias `"latest"`. If omitted, the launcher will automatically use semantic version sorting to infer the latest version.
* `system: "all"` means the solver supports all platforms.
* The `build.dependencies` section supports both Git and direct URL downloads.
* When downloading archives, the launcher ensures extracted content is flattened (i.e., removes redundant directory nesting).

---

## 🔍 Configuration File Discovery

Solver configuration files are searched in:

* **System directory**: `/usr/share/xcsp-launcher/configs`
* **User directory**: `~/.config/xcsp-launcher/solvers`

A **cache file** is automatically maintained at:

```bash
~/.cache/xcsp-launcher/solver_cache.json
```

To inspect all resolved paths used by XCSP Launcher:

```bash
xcsp --info
```
