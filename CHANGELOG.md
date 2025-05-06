## v0.1.0a2 (2025-05-06)

### Feat

- **builder/build.py**: run each build step separately for improved error handling

### Fix

- **commands/install.py,-solver/solver.py**: Switch solver command to list to properly handle paths containing spaces

## v0.1.0a1 (2025-05-02)

### Feat

- **solver/resolver.py**: Supported more extension for searching configuration file
- **commands/solver.py**: adds JSON output for the list of solvers

### Fix

- **solver/solver.py**: Fixes a bug that ignore the version from CLI
- **Makefile**: fixes some bugs with brew
- **pyproject.toml**: Fixes some problems with the pypi package.
- **Makefile**: deb from pyinstaller

### Refactor

- **xcsp/main.py,-bin/main.py**: the main function is now in xcsp/main.py
- **main.py**: Adds a method main()
- **Makefile**: refactoring Makefile
