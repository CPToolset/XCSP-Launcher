# ⚙️ Solving an Instance

`xcsp solver` is the primary subcommand used to run a solver on an XCSP3 instance.

---

## 🧾 CLI Reference

```bash
xcsp solver [-h] [--name NAME] [--solver-version SOLVER_VERSION]
            [--instance INSTANCE] [-a] [-n NUM_SOLUTIONS] [-i]
            [-p PARALLEL] [-r RANDOM_SEED] [--timeout TIMEOUT]
            [--keep-solver-output] [--json-output] [--stdout STDOUT]
            [--stderr STDERR] [--prefix PREFIX] [--tmp-dir TMP_DIR]
            [--solvers]
            [solver_options ...]
```

| Argument | Description                                                            |
|----------|------------------------------------------------------------------------|
| `--name` | Name of the solver (e.g., `ace`)                                       |
| `--solver-version` | Specific version to use (default: `latest`)                            |
| `--instance` | Path to the `.xml` file representing the XCSP3 instance                |
| `-a`, `--all-solutions` | Retrieve all solutions (satisfaction) or improving ones (optimization) |
| `-n`, `--num-solutions` | Stop after a given number of solutions                                 |
| `-i`, `--intermediate` | Print intermediate assignments during search                           |
| `-p`, `--parallel` | Number of threads to use for solving                                   |
| `-r`, `--random-seed` | Fix the seed for reproducibility                                       |
| `--timeout` | Time limit in seconds                                                  |
| `--keep-solver-output` | Show solver logs (stdout/stderr), line-prefixed                        |
| `--json-output` | Print results as JSON instead of standard log output                   |
| `--stdout`, `--stderr` | Redirect solver output to file or stdout/stderr                        |
| `--prefix` | Prefix for solver output lines (if shown)                              |
| `--tmp-dir` | Temporary directory for files generated during solving                 |
| `--solvers` | Show a list of installed solvers                                       |
| `solver_options ...` | Extra options passed **after** `--` directly to the solver CLI         |

---

## 📥 Listing Available Solvers

To see all installed solvers:

```bash
xcsp solver --solvers
```

```bash
                                                                                     Solver List                                                                                      
┏━━━━━━┳━━━━━━━━━━━━━━━━━━┳━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━┓
┃ Name ┃        ID        ┃ Version ┃ Command Line                                                                                                                          ┃ Alias  ┃
┡━━━━━━╇━━━━━━━━━━━━━━━━━━╇━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━┩
│ ACE  │ fr.cril.xcsp.ace │   2.4   │ /usr/bin/java -jar /home/user/.local/share/xcsp-launcher/bin/fr.cril.xcsp.ace/2.4-2.4/ACE-2.4.jar {{instance}} -npc=true -ev        │ latest │
│ ACE  │ fr.cril.xcsp.ace │   2.3   │ /usr/bin/java -jar /home/user/.local/share/xcsp-launcher/bin/fr.cril.xcsp.ace/2.3-2.3/ACE-2.3.jar {{instance}} -npc=true -ev        │        │
│ ACE  │ fr.cril.xcsp.ace │ 2.4dev  │ /usr/bin/java -jar /home/user/.local/share/xcsp-launcher/bin/fr.cril.xcsp.ace/2.4dev-c61dd75/ACE-2.4.jar {{instance}} -npc=true -ev │ dev    │
└──────┴──────────────────┴─────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴────────┘
```



To list them as JSON (useful for scripting or IDE integration):

```bash
xcsp solver --solvers --json-output
```

```json
[
    {
        "id": "ACE@2.4",
        "version": "2.4",
        "cmd": "/usr/bin/java -jar /home/user/.local/share/xcsp-launcher/bin/fr.cril.xcsp.ace/2.4-2.4/ACE-2.4.jar {{instance}} -npc=true -ev"
    },
    {
        "id": "ACE@2.3",
        "version": "2.3",
        "cmd": "/usr/bin/java -jar /home/user/.local/share/xcsp-launcher/bin/fr.cril.xcsp.ace/2.3-2.3/ACE-2.3.jar {{instance}} -npc=true -ev"
    },
    {
        "id": "ACE@2.4dev",
        "version": "2.4dev",
        "cmd": "/usr/bin/java -jar /home/user/.local/share/xcsp-launcher/bin/fr.cril.xcsp.ace/2.4dev-c61dd75/ACE-2.4.jar {{instance}} -npc=true -ev"
    }
]
```


---

## 🧪 Solving an Instance

### Basic usage

```bash
xcsp solver --name ace --instance StillLife-wastage-05-05_c24.xml
```

<script src="https://asciinema.org/a/Fu8WfuI7m1tSJ2wZ5YBlPEaFq.js" id="asciicast-Fu8WfuI7m1tSJ2wZ5YBlPEaFq" async="true"></script>

### With a specific version

```bash
xcsp solver --name ace --solver-version 2.3 --instance StillLife-wastage-05-05_c24.xml
```

<script src="https://asciinema.org/a/7Wrp6e0NauVxu9WanGBdpdjNW.js" id="asciicast-7Wrp6e0NauVxu9WanGBdpdjNW" async="true"></script>

### Limit the number of solutions

```bash
xcsp solver --name ace --instance StillLife-wastage-05-05_c24.xml -n 4
```

<script src="https://asciinema.org/a/AkHiFf8cC1TROjBeWIsV0OAyv.js" id="asciicast-AkHiFf8cC1TROjBeWIsV0OAyv" async="true"></script>


### Pass additional options to the solver

You can add solver-specific arguments at the end, using `--`:

```bash
xcsp solver --name ace --instance foo.xml -- -varh=RunRobin
```

---

## 📤 Output Modes

- **Standard Output**: By default, results are printed to the console.
- **JSON Output**: Use `--json-output` to get structured results.
- **Log Redirection**: You can redirect `stdout` and `stderr` using `--stdout` and `--stderr`.

Example:

```bash
xcsp solver --name ace --instance foo.xml --stdout results.out --stderr errors.log
```

This will redirect the **output of the solver** (and **only** the solver) respectively to `result.out` for `stdout` and `errors.log` for `stderr`. 

---

## 📌 Notes

- Solvers must be installed beforehand via [`xcsp install`](solver_installation.md).
- The `--solvers` flag is useful to check if a solver is ready before launching.
