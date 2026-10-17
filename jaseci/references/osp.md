# Object-Spatial Programming: nodes, edges, walkers (offline fallback)

Prefer `jac guide jac-node-edge-patterns` and `jac guide jac-walker-patterns`.
Verified on jaclang 0.16.x.

Concept: data lives in a graph rooted at `root`. Instead of pulling data to the
computation, you send a **walker** through the graph and it runs code on each node it visits.

```jac
node Person {
    has name: str;
    has age: int = 0;
}

edge Follows: Person --> Person {      # typed edge with endpoint types
    has since: int = 2024;
}

walker CountAdults {
    has count: int = 0;
    has reports: list[int] = [];      # default is required

    can start with Root entry {
        visit [-->[?:Person]];         # queue root's Person children
    }

    can check with Person entry {
        if here.age >= 18 { self.count += 1; }
        visit [here ->:Follows:->];    # keep walking along Follows edges
    }

    can done with Root exit {          # exit abilities fire after the walk (LIFO)
        report self.count;
    }
}

with entry:__main__ {
    alice = (root ++> Person(name="alice", age=30))[0];    # ++> returns a LIST
    bob = Person(name="bob", age=17);
    alice +>:Follows(since=2020):+> bob;                    # typed connect

    print([p.name for p in [alice ->:Follows:->]]);         # typed traversal
    print([p.name for p in [root -->[?:Person, age > 20]]]); # filter by type + comparison
    print([e.since for e in [edge alice ->:Follows:->]]);   # edge objects

    res = root spawn CountAdults();
    print(res.reports[0] if res.reports else 0);            # 1 (bob visited via alice)
}
```

## Cheat sheet

| Want | Write |
|---|---|
| connect (untyped) | `a ++> b;` (returns list of targets) |
| connect typed | `a +>:E(f=1):+> b;` |
| bidirectional | `a <++> b;` |
| outgoing / incoming / both | `[a -->]`, `[a <--]`, `[a <-->]` |
| typed edge traversal | `[a ->:E:->]`, `[a <-:E:<-]` (single arrows!) |
| filter by type / field | `[a -->[?:T]]`, `[a -->[?:T, age > 3]]` |
| boolean-field filter | `[n for n in [a -->[?:T]] if n.done]` |
| multi-hop | `[a ->:E:-> ->:E:->]` |
| edge objects | `[edge a ->:E:->]` |
| bulk update | `[root -->[?:T]](=done=True);` |
| delete node (+ its edges) | `del n;` |
| disconnect untyped | `a del --> b;` |
| delete typed edge | `for e in [edge a ->:E:-> b] { del e; }` |
| stable id / lookup | `jid(n)`, `jobj(id_str)` |
| print graph | `print(printgraph(root));` |

## Walker rules

- Ability syntax: `can name with NodeType entry { }` / `... exit { }`. Union: `with A | B entry`.
- In a **walker** ability, `self` is the walker and `here` is the current node.
  In a **node** ability (`can x with MyWalker entry`), `self` is the node and `visitor` is the walker.
- `visit [-->];` queues nodes (breadth-first). `visit :0: [-->];` puts them at
  the front of the queue (depth-first). `visit [...] else { ... }` runs the
  else block when nothing was queued, which makes a get-or-create pattern.
- `skip;` ends the current ability, `disengage;` stops the walker entirely.
- `report x;` appends to `result.reports` (and prints). Walkers don't `return`.
- A walker's bare `with entry` only fires where it was spawned, not on every node.
- The spawn node itself runs matching abilities (watch for off-by-one counts).
- Edge abilities never fire. Put logic in node/walker abilities.
- Inheritance: `walker Sub(Base) { override can x with Root entry { } }`.
- Graph persists in `.jac/`. Reset with `rm -rf .jac` after changing node schemas.
