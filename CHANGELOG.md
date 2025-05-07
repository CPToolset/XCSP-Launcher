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
