# Contributing to XCSP-Launcher

XCSP-Launcher is a unified command-line tool for installing, configuring, and running XCSP3-compatible constraint solvers. This document outlines how you can contribute and the development conventions to follow.

---

## 🛠️ Prerequisites

- Python 3.8+
- [`pip`](https://pip.pypa.io/) and [`virtualenv`](https://virtualenv.pypa.io/)
- [`make`](https://www.gnu.org/software/make/) (for building cross-platform binaries)
- [`pytest`](https://docs.pytest.org/) and [`pytest-xdist`](https://pypi.org/project/pytest-xdist/) for running the tests
- [`commitizen`](https://commitizen-tools.github.io/commitizen/) for managing versioning and changelogs

---

## 🧑‍💻 Development Setup

```bash
git clone https://github.com/CPToolset/xcsp-launcher.git
cd xcsp-launcher

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install .

# Run initial bootstrap (to install default solvers)
xcsp --bootstrap
```

---

## 🧪 Running Tests

You can run the full test suite using:

```bash
python -m pytest -n 4 tests/
```

Note: Some tests assume that solvers (like ACE) have already been installed via `xcsp --bootstrap`.

---

## 🧪 Testing Instances

Instances used for testing are stored under:

```
tests/xcsp3/cop/
├── SAT/        # Known satisfiable
├── UNSAT/      # Known unsatisfiable
└── UNKNOWN/    # No known result
```

Each SAT instance is accompanied by a `solutions.json` file describing expected behavior per solver/version.

---

## 📝 Making Commits

We use **Conventional Commits** via [`Commitizen`](https://commitizen-tools.github.io/commitizen/):

```bash
cz commit
```

This allows generating changelogs and managing versions automatically.

To bump the version and tag a release:

```bash
cz bump
git push && git push --tags
```

Pre-release example:

```bash
cz bump --prerelease alpha
```

---

## 🚀 Building the project

You can build the project with:

```bash
make build 
make pyinstaller 
make [deb|snap|choco|brew]
```

This will generate:
- A Python wheel + sdist (`dist/`)
- A PyInstaller binary
- Debian (`.deb`), Snap (`.snap`), Chocolatey (`.nupkg`), and Homebrew formula (`brew/`)

---

## 🙌 Need Help?

- Read the [README.md](./README.md)
- Open an [issue](https://github.com/CPToolset/xcsp-launcher/issues)

---
