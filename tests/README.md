# 🧪 XCSP-Launcher — Test Suite

This directory contains functional and integration tests for the `xcsp-launcher` project.

---

## 🛠️ Requirements

Tests rely on [`pytest`](https://docs.pytest.org/en/latest/) with the [`pytest-xdist`](https://pypi.org/project/pytest-xdist/) extension for parallel execution:

```bash
pip install pytest pytest-xdist
```

---

## 🚀 Running Tests

From the project root, you can run all tests in parallel using:

```bash
python -m pytest -n 4 tests/
```

This launches tests across 4 workers for faster execution.

---

## ⚠️ Precondition: Solvers Must Be Installed

These tests assume that at least one solver (especially **ACE**) is already installed via `xcsp-launcher`.  
You can install default solvers using the bootstrap command:

```bash
xcsp --bootstrap
```

---

## 📂 Test Structure

Inside `tests/xcsp3/cop/` you’ll find subdirectories organized by expected solver behavior:

### ✅ `SAT/`

Contains **satisfiable** instances that solvers (such as ACE) are known to solve within a **reasonable amount of time**.

Example:

```
tests/xcsp3/cop/SAT/
├── solutions.json
└── StillLife-wastage-05-05_c24.xml
```

The `solutions.json` file describes the expected behavior of a solver on each instance:

```json
{
  "ace@latest": {
    "StillLife-wastage-05-05_c24.xml": {
      "instance": "StillLife-wastage-05-05_c24.xml",
      "solutions": [0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 16],
      "last_is_optimum": true
    }
  }
}
```

### ❌ `UNSAT/`

Contains instances **known to be unsatisfiable**, and proven as such by ACE within a reasonable time.  
Tests check that the solver returns the `UNSATISFIABLE` status.

### ❓ `UNKNOWN/`

Contains instances **not solved** by ACE within a 10-second timeout.  

---

If you add a new solver or test instance, don’t forget to update the corresponding `solutions.json` file.
