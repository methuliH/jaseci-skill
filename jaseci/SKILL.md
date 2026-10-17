---
name: jaseci
description: Write, run, debug and ship programs in Jac, the Jaseci programming language (jaclang). Covers Object-Spatial Programming (nodes, edges, walkers, spawn/visit/report), byLLM AI functions (`by llm`, `sem`), REST APIs with `jac start`, full-stack apps with `.cl.jac` client components, jac.toml, `jac check`/`jac test`, and deployment with jac-scale. Use this skill whenever the user mentions Jac, Jaseci, jaclang, a `.jac` file, walkers or nodes in a graph-programming sense, byLLM, jac-client, jac-scale, `jac guide`, or is building a project for a Jaseci/Jac hackathon, even if they just say "build me an app in Jac" or paste Jac code that looks like Python with braces.
---

# Jac / Jaseci

Jac is a Python-superset language (braces and semicolons, strict types) that adds
graph-native programming (nodes, edges, walkers), AI functions (`by llm`), built-in
persistence, auto-generated REST endpoints and a React-compiling client layer.
Jaseci is the runtime/ecosystem around it.

**Why this skill exists:** Jac changes fast and looks like Python, so models
write Python, JSX or out-of-date Jac that fails to compile. The cure is to
lean on the compiler: the `jac` CLI ships version-matched guides (`jac guide`)
and a type checker (`jac check`) whose diagnostics point at the right guide.
Treat those as the source of truth over memory and over this file.

## Workflow

1. **Get the toolchain.** Run `bash <skill-dir>/scripts/ensure_jac.sh` (add
   `--with-llm` if the task uses `by llm`). It installs `jaclang` if needed
   and lists the guides available *for the installed version*. Guide names
   vary between versions, so pick from that list, not from memory.
   No shell access or the install fails? Fall back to `references/`, and
   tell the user the code hasn't been compiled.

2. **Load the right guide(s) before writing code.** Always read
   `jac guide jac-core-cheatsheet` first (it's short and prevents most syntax
   errors). Then load only what the task needs (see the routing table
   below). For large guides, use `jac guide <name> --sections` and then
   `--section <slug>`. `jac guide --search <word>` finds guides by keyword.

3. **Write code**, borrowing structure from `examples/` (all compile and run
   on jaclang 0.16.x).

4. **Check with the compiler:**
   - `jac check <file-or-dir>`: fix **all errors**, and most warnings too.
     A `W1051 Unknown type` warning usually means a missing type annotation
     or a bad import that will bite later. Each diagnostic names a guide
     (`→ run 'jac guide jac-types'`). Read it rather than guessing.
   - `jac run file.jac` for scripts, `jac test file.jac` for `test "..." {}` blocks,
     `jac start main.jac --no_client` for APIs (then hit it with curl).
   - Graph state persists in `.jac/` between runs. If you change node
     definitions or re-run a seeding script, `rm -rf .jac` (or `jac clean --all`
     inside a project) first. Otherwise you get duplicates or
     `NodeAnchor ... is not a valid reference`.
   - Iterate until `jac check` passes and the program behaves as intended.
     Only then hand code back, saying what you ran.

## Routing: which guide for which task

| Task | `jac guide ...` |
|---|---|
| New project, unsure of shape | `jac-project-kinds`, `jac-scaffold` |
| Any Jac at all | `jac-core-cheatsheet`, `jac-types` |
| Objects with fields | `jac-has-fields` |
| Graph data model / queries | `jac-node-edge-patterns` |
| Walkers, spawn, visit, report | `jac-walker-patterns` |
| LLM-powered functions, agents, tools | `jac-by-llm` |
| REST API endpoints | `jac-sv-endpoints`, `jac-sv-persistence`, `jac-sv-auth` |
| Multi-user / shared data | `jac-sv-multi-user` |
| Full-stack web app | `jac-fullstack-patterns`, `jac-cl-components`, `jac-cl-routing`, `jac-cl-styling` |
| Calling Python libs (numpy, pandas...) | `jac-python-interop` |
| Tests | `jac-testing` |
| Something is broken or stale | `jac-debugging` |
| jac.toml / dependencies | `jac-config` |
| Deploy / Kubernetes | `jac-sv-deploy` |

Offline summaries of the most-used topics are in `references/`:
`syntax.md`, `osp.md`, `byllm.md`, `server-and-fullstack.md`. Read one only when
the CLI guides aren't available, or for a fast refresher.

## Mistakes that break most first drafts

Check every draft against this list. Each item cost a failed compile when
testing this skill or is called out repeatedly in the official guides.

- Every statement ends in `;`, every block uses `{ }`. **Exception:** `match`
  arms use Python-style `case X:` plus an indented body.
- Top-level code goes in `with entry { ... }`. Use `with entry:__main__ { ... }`
  for code that must not run on import.
- Brace imports take **no** semicolon: `import from math { pi }`.
  Plain ones do: `import os;`. There is no `import:py`.
- Types are required on every `def` parameter and return, and on every `has` field.
  `True/False/None` are capitalized. Ternary is `a if c else b`, never `c ? a : b`.
  No `pass` statement: write an empty block `{}`.
  Typing is strict: comparing a `float` to an `int` literal (`pi > 3`) is an
  error, so write `3.0`.
- Lambdas must be typed: `lambda x: int : x + 1`.
- **Reserved words can't be names**: `node edge walker obj visit report spawn
  disengage skip can has with flow wait del by impl`… (e.g. a parameter named `report`
  fails E0013). Rename them; don't backtick-escape `has` fields.
- `glob` declarations are module-level only (not inside `test` or `def`).
- Use `node`/`edge` for things stored in the graph and `obj` for plain data.
  Nodes must be connected to `root` (directly or via a path) to be found again.
- `root ++> X(...)` returns a **list**. Take `[0]` to get the node.
- Typed edge connect: `a +>:E(f=1):+> b`. Typed traversal: `[a ->:E:->]`
  (single arrows). Filters take type plus comparisons: `[root -->[?:Task, points > 1]]`.
  `[?:Task, not done]` is a parse error. For boolean fields use a
  comprehension: `[t for t in [root -->[?:Task]] if not t.done]`.
- Walker abilities are `can name with NodeType entry { ... }`, not `def`.
  In a walker, `self` is the walker and `here` is the current node. In a node
  ability, `self` is the node and `visitor` is the walker.
  `visit [-->];` is a statement. Walkers `report`, they don't `return`.
- Results: `res = root spawn W(); res.reports[0]`. Give walkers
  `has reports: list[T] = [];` (the default is required). Accumulate during the
  walk and report once from a `with Root exit` ability.
- `by llm()` **replaces** the body: `def f(x: str) -> T by llm();`. Describe
  things with `sem f = "...";` / `sem f.x = "...";`, not docstrings. There
  are no inline `"prompt" by llm` expressions. Tools are function references.
  Tests use `MockLLM` so they need no API key.
- Endpoints: `walker:pub` / `def:pub` are public. Plain `def`/`walker` need auth.
  `jac start` needs a `jac.toml` and uses underscore flags (`--no_client`).
- Client files (`.cl.jac`) are **Jac, not JSX/JS**. State is `has`, effects
  are `can with entry`, the entry is `def:pub app()`. Server calls use
  `sv import` and must be `await`ed.

## Hackathon-friendly defaults

When the user just wants something working fast:
- Start with a single `main.jac` plus a `jac.toml` (copy `examples/api_service/`),
  or `jac create <name> --kind <kind>` (`jac create --list_jacpacks` lists kinds,
  e.g. `api-service`, `fullstack`; full-stack needs the jac-client plugin).
- Model the domain as nodes and edges first, then expose `def:pub` functions
  (simplest) or `walker:pub` walkers. Swagger is served at `/docs` for demos.
- Add AI with a typed `by llm()` function that returns an `obj` or `enum`.
  Set the model in jac.toml (`[plugins.byllm.model] default_model = "gpt-4o-mini"`)
  plus the provider key env var (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`...), or
  `ollama/<model>` for local models.
- Mention `jac guide --export .claude/skills` to the user if they want every
  official guide auto-loaded as Claude skills in their repo, and `jac mcp`
  for an MCP server with live compile/format tools.

## Examples (all verified)

- `examples/graph_walker.jac`: nodes, typed edges, filters, a walker that
  totals values during the walk and reports once. Run: `jac run graph_walker.jac`.
- `examples/llm_functions.jac`: `by llm` returning an `obj` and an `enum`,
  `sem` descriptions, a MockLLM test. Run: `jac test llm_functions.jac`.
- `examples/api_service/`: `walker:pub` + `def:pub` REST API with find-by-`jid`.
  Run: `jac start main.jac --no_client`.

## Resources

Docs: https://jaclang.org/docs/latest · Source: https://github.com/jaseci-labs/jac ·
Site: https://jaseci.org · Playground: https://playground.jaseci.org
