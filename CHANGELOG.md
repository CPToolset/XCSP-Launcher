## v0.6.1 (2025-08-12)

### Fix

- **builder/build.py**: Fixes a bug with the build part of a solver

## v0.6.0 (2025-08-06)

### Feat

- **commandes/install.py**: Compute the latest version based on the version in configuration file
- **configs/**: updates the submodule
- **builder/build.py**: Use the new configuration file
- **builder/check.py**: Add the C language

### Fix

- **commands/install.py**: Fixes a bug when the list of version is empty
- **utils/placeholder.py**: Replace bin_dir in command_line before generated cache file
- **commands/solver.py**: Force removing instance when there is an exception

### Refactor

- **commands/solver.py,-utils/bootstrap.py,-main.py**: Some minor change
- **commands/__init__.py,-commands/install.py**: Big refactoring for installaation of a solver
- **solver/*.py**: change the import of the paths package
- **utils/softwarevers.py**: creates some function for managing semantic versionning of solvers
- **utils/placeholder.py**: Some refactoring in placeholder module
- **utils/paths.py**: Adds a function for getting the root path for the binaries of solvers
- **utils/http.py**: utils functions for downloading and HTTP url
- **utils/dict.py**: Util function for dictionnary
- **utils/args**: module for managing some constraint on command line arguments
- **utils/archive.py**: New module for managing the extraction of archive
- **utils/versiondir**: add package to manage versioned directories from archives or git
- **system.py**: Add a function "normalized_system_name", new module in utils package

## v0.5.1 (2025-06-09)

### Fix

- **system.py**: Improves error message when trying to kill a process after a timeout

## v0.5.0 (2025-06-09)

### Feat

- **solver.py**: Enforce timeout by introducing a dedicated thread for timeout management

### Fix

- **main.py**: Fail gracefully if no subcommand is provided

## v0.4.0 (2025-05-14)

### Feat

- **xcsp**: Check solution from CLI.
- **xcsp/**: Check solution with API

## v0.3.0 (2025-05-11)

### Feat

- **commands/solver.py,-solver/solver.py**: Decompress LZMA file before launching solver

### Fix

- **solver/solver.py**: Check if the key of the default option is present
- **placeholder.py**: strip options adding to the command line

## v0.2.1 (2025-05-09)

### Fix

- **solver/solver.py**: prevent duplicate options by copying base command

## v0.2.0 (2025-05-09)

### Feat

- **solver/solver.py**: Improve CLI management to support running the solver multiple times

## v0.1.1 (2025-05-09)

### Fix

- **solver/solver.py,-utils/placeholder.py**: Fixes a problem with the command line and the placeholders

## v0.1.0 (2025-05-07)

### Fix

- **placeholder.py**: Fixes a bug when the placeholder is replaced

## v0.1.0a5 -> v0.1.0a17 (2025-05-06)

### CI

- Tags created to troubleshoot and stabilize GitHub Actions workflows

## v0.1.0a4 (2025-05-06)

### Feat

- **main.py**: Adds a command "--info" for printing a summary of paths using by xcsp-launcher

## v0.1.0a3 (2025-05-06)

### Feat

- **commands/install.py**: Support system filtering, case-insensitive placeholders, and dependencies

## v0.1.0a2 (2025-05-06)

### Feat

- **builder/build.py**: run each build step separately for improved error handling

### Fix

- **commands/install.py,-solver/solver.py**: Switch solver command to list to properly handle paths containing spaces

## v0.1.0a1 (2025-05-02)

### Feat

- **commands/install.py**:
    - install solver from configuration file 
    - install solver from repo 
    - install solver from git
- **commands/solver.py**:
    - run solver without specify version
    - run solver using specific version 
    - keep solver output or not 
    - prefix the solver output
    - redirect solver output 
    - JSON output for the list of solvers
    - JSON output for the output of the solvers 
