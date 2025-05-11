# 🐍 Python Library Usage

XCSP Launcher can also be used as a **Python library**, enabling programmatic control over solver configuration, 
execution, and output parsing. 
This is ideal for integrating XCSP3-based solving into larger Python workflows or research experiments.

---

## 🔍 List available solvers

You can list all solvers currently installed and recognized by XCSP Launcher:

```python
from xcsp.solver.solver import Solver

solvers = Solver.available_solvers()
```

This returns a dictionary of the form:

```python
{
  "ace@2.4": <Solver object>,
  "cosoco@latest": <Solver object>,
  ...
}
```

Each key is a combination of `name@version`, and the values are [`Solver`](https://xcsp.readthedocs.io/en/latest/api.html#xcsp.solver.solver.Solver) objects.

---

## ⚙️ Create and configure a solver

To retrieve a solver instance:

```python
solver = Solver.lookup("ace")               # latest version of ACE
solver = Solver.lookup("ace@2.4")           # specific version
```


You can configure the solver using standard methods that correspond to the options described in the 
[solver configuration schema](https://xcsp.readthedocs.io/en/latest/solver_configuration.html#command-line-execution). 
These methods map directly to standard configuration options. If a solver does not support a particular option, 
then calling the corresponding method will have no effect:

```python
solver.set_limit_number_of_solutions(10)             # limit number of solutions
solver.set_seed(1234)                                # set random seed
solver.set_time_limit(5)                             # 5 seconds timeout
solver.all_solutions(True)                           # enable all solutions search
solver.set_collect_intermediate_solutions(True)      # print intermediate assignments
solver.set_json_output(True)                         # JSON output instead of CLI
solver.add_complementary_options(["-varh=RunRobin"]) # custom CLI options
```


### Optional: redirect output

```python
solver.set_output("stdout")      # or a path to file
solver.set_error("stderr")       # or a path to file
```

---

## 🧠 Solver metadata

You can access solver details through these properties:

```python
solver.id        # e.g., 'fr.cril.xcsp.ace'
solver.name      # e.g., 'ACE'
solver.version   # e.g., '2.4'
solver.cmd       # full solver command template
```

---

## 🚀 Solving an instance

Once configured, you can launch the solver on an XCSP3 instance:

```python
results = solver.solve("path/to/instance.xml")
```

If you want to keep live output from the solver:

```python
results = solver.solve("path/to/instance.xml", keep_solver_output=True)
```

The return value is a dictionary of the form:

```json
{
  "status": "SATISFIABLE",
  "bounds": [
    {"value": 42, "wall_clock_time": 0.2, "cpu_time": 0.1},
    ...
  ],
  "assignments": [
    {"solution": "x1=0 x2=1 x3=2", "wall_clock_time": 0.3, "cpu_time": 0.2},
    ...
  ],
  "wall_clock_time": 1.45,
  "cpu_time": 1.12
}
```

---

## ✅ Interpreting the status

The final solver status is available as an enum:

```python
from xcsp.solver.solver import ResultStatusEnum

solver.status() == ResultStatusEnum.SATISFIABLE
solver.objective_value()  # Get last objective value found (if any)
```

Possible statuses include:

* `SATISFIABLE`
* `UNSATISFIABLE`
* `OPTIMUM FOUND`
* `UNKNOWN`
* `TIMEOUT`
* `MEMOUT`
* `ERROR`

---

## 📚 See also

* 🔧 [Solver Configuration Format](solver_configuration.md)
* 🖥️ [Command Line Usage](cli.md)
* 🧩 [API Reference](api.md)
