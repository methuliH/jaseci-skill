# Jac core syntax (offline fallback)

Prefer `jac guide jac-core-cheatsheet` and `jac guide jac-types`, which match the
installed version. This is a snapshot verified against jaclang 0.16.x.

## Shape of a program

```jac
import os;                       # plain import: needs ;
import from math { pi, sqrt }    # brace import: NO ;

glob counter: int = 0;           # module-level variable (only at module level)

obj Point {                      # plain data class (not stored in the graph)
    has x: float = 0.0;
    has y: float = 0.0;

    def dist(other: Point) -> float {
        return sqrt((self.x - other.x) ** 2 + (self.y - other.y) ** 2);
    }
}

enum Color { RED, GREEN, BLUE }
enum Status: str { OPEN = "open", CLOSED = "closed" }   # members ARE strs: no .value

def bump(amount: int = 1) -> int {
    global counter;
    counter += amount;
    return counter;
}

with entry {                     # runs on every import
    print(pi > 3.0);              # strict: float vs int literal is E1110
}

with entry:__main__ {            # runs only when executed directly
    p = Point(x=3.0, y=4.0);
    print(p.dist(Point()));
    print(bump(), Color.RED, Status.OPEN == "open");

    nums: list[int] = [1, 2, 3, 4];
    evens = [n for n in nums if n % 2 == 0];
    label = "many" if len(evens) > 1 else "few";
    sq = lambda x: int : x * x;
    print(f"{label}: {[sq(e) for e in evens]}");

    for i in range(3) {
        if i == 0 { continue; }
        elif i == 2 { break; }
        else { print(i); }
    }
    while counter < 3 { bump(); }

    try {
        _ = int("nope");
    } except ValueError as e {
        print(f"bad: {str(e)}");
    }

    match len(nums) {
        case 0:
            print("empty");
        case int() as n if n > 3:
            print(f"big list of {n}");
        case _:
            print("small list");
    }
    print(os.sep != "");
}
```

## Rules that trip people up

- `;` after every statement, `{}` around every block. `match`/`case` arms are the
  one place that uses colon plus indentation.
- Explicit types on all `def` params/returns and `has` fields; `any` is the escape
  hatch, `x as T` casts. The checker is strict: `pi > 3` (float vs int) is an
  error, so write `pi > 3.0`.
- `True`, `False`, `None`. No `pass` (use `{}`). No `? :` ternary.
- Docstrings go *before* a declaration, never inside the body.
- Unused variables warn (W2003). Use `_` or a `_name` prefix.
- Reserved words (`node edge walker obj visit report spawn disengage skip can has
  with flow wait del impl def by`) can't be variable or parameter names.
- Python stdlib must be imported explicitly. Any PyPI package can be imported
  directly (`import numpy as np;`).
- `x?.attr` / `d?["k"]` are null-safe and return `None` instead of raising.
- Methods inside `obj`/`node`/`walker` use `def`. Graph-event abilities use `can ... with ... entry`.
- Declarations and bodies can be split: `def f(x: int) -> int;` then
  `impl f(x: int) -> int { ... }` (often in `file.impl.jac`).

## CLI

| Command | Purpose |
|---|---|
| `jac run f.jac` | run a script (`with entry` blocks) |
| `jac check f.jac` / `jac check .` | type-check + diagnostics |
| `jac test f.jac` | run `test "name" { ... }` blocks |
| `jac format f.jac` | format |
| `jac lint --fix .` | lint and auto-fix |
| `jac start main.jac --no_client` | serve walkers/`def:pub` as REST |
| `jac create name --kind api-service` | scaffold a project |
| `jac py2jac f.py` / `jac jac2py f.jac` | convert between Python and Jac |
| `jac dot f.jac` | graph visualization (DOT) |
| `jac clean --all` / `rm -rf .jac` | reset persisted graph & caches |
| `jac guide [name]` | built-in, version-matched reference |
