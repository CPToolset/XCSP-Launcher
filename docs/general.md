# 🔧 General Usage

```bash
usage: xcsp [-l {TRACE,DEBUG,INFO,SUCCESS,WARNING,ERROR,CRITICAL}] [-h] [-v]
            [--bootstrap]
            {install,i,solver,s} ...
```

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Display help message for the main CLI or any subcommand |
| `-v`, `--version` | Show the current version of XCSP Launcher |
| `-l`, `--level` | Set the logging level for console output (see below) |
| `--bootstrap` | Automatically install default solvers from system configuration |

---

## 📦 Available Subcommands

### 🔧 `install`
Install a solver from a configuration file, a repository, or a URL.  
See full usage: [Solver Installation](install_solver.md)

### 🚀 `solver`
Run a solver on an XCSP3 instance.  
See full usage: [Solving an Instance](solving.md)

You can also list installed solvers with:

```bash
xcsp solver --solvers
```

---

## 🪵 Logging

You can control the verbosity of the CLI using the `--level` option.  
This feature is powered by the [Loguru](https://github.com/Delgan/loguru) logging library.

Available log levels:

- `TRACE`
- `DEBUG`
- `INFO` (default)
- `SUCCESS`
- `WARNING`
- `ERROR`
- `CRITICAL`

Example:

```bash
xcsp --level DEBUG solver --name ace --instance queens.xml
```

This will output more detailed execution logs (from `xcsp-launcher`) during the run. 
This option not control the verbosity of the solver. 


