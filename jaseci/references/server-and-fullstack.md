# Servers, APIs and full-stack apps (offline fallback)

Prefer `jac guide jac-sv-endpoints`, `jac-fullstack-patterns` and `jac-cl-components`.
Verified on jaclang 0.16.x.

## REST API (server)

Needs a `jac.toml` (at least `[project] name/version/entry-point`). See
`examples/api_service/`.

```jac
node Item {
    has title: str;
    has done: bool = False;
}

def:pub list_items() -> list[Item] {          # POST /function/list_items
    return [root -->[?:Item]];
}

walker:pub add_item {                          # POST /walker/add_item  body: {"title": "..."}
    has title: str;
    can make with Root entry {
        report (root ++> Item(title=self.title))[0];
    }
}
```

- `jac start main.jac --no_client` (underscore flags). Swagger at `/docs`.
- `def:pub` / `walker:pub` are public. Plain or `:priv` need a JWT (`/user/register`,
  `/user/login`), and each user gets an isolated `root`. `_helper` stays off the API.
- Response envelope: `{"ok": true, "data": {"result": ..., "reports": [...]}, "error": null}`.
- Custom method/path: `import from http { HTTPMethod }` plus
  `@restspec(method=HTTPMethod.GET, path="/items/{item_id}")`.
- Pass `jid(node)` strings across the wire. Look nodes up again by looping and
  comparing `jid(n) == id`, or with `jobj(id)`.
- Return types are the wire format. Return nodes/objs, not hand-built dicts.
- Schema edited and now getting "Invalid anchor id"? Stop the server and `rm -rf .jac/data`.
- Deploy: `jac start main.jac --scale` (jac-scale plugin, k8s). See `jac guide jac-sv-deploy`.

## Full-stack (needs jac-client plugin; `jac create app --kind fullstack`)

> The client snippets below follow the official guides but weren't compiled
> when this skill was built (jac-client wasn't installed). Run `jac check .`
> on the real project.

```
main.jac                  # server imports + cl { } block with def:pub app()
services/todos.jac        # def:pub endpoints
components/TodoList.cl.jac
jac.toml                  # [serve] base_route_app = "app"
```

main.jac:
```
import from services.todos { Todo, list_todos, add_todo }

cl {
    import from .components.TodoList { TodoList }
    def:pub app() -> JsxElement { return <TodoList />; }
}
```

components/TodoList.cl.jac (this is **Jac**, not JS/JSX):
```
sv import from ..services.todos { Todo, list_todos, add_todo }

def:pub TodoList() -> JsxElement {
    has todos: list[Todo] = [];
    has text: str = "";

    async can with entry { todos = await list_todos(); }      # mount effect

    async def add(e: FormEvent) {
        e.preventDefault();
        await add_todo(text);           # RPC args are POSITIONAL, named like server params
        todos = await list_todos();     # write then refetch
        text = "";
    }
    def on_text(e: ChangeEvent) { text = e.target.value; }

    return <form onSubmit={add}>
        <input value={text} onChange={on_text} />
        <ul>{[<li key={jid(t)}>{t.title}</li> for t in todos]}</ul>
    </form>;
}
```

- State is `has` (assign directly to re-render). Effects are `can with entry` /
  `can with [dep] entry`. Props are typed params (`children: any = None`).
- `JsxElement`, DOM event types and `Callable` are built in. Never import them.
- Calls via `sv import` are async, so always `await` them. Walker calls from the
  client: `res = root spawn add_item(title=t);` (kwargs) then `res.reports[0]`.
- Routing, auth and helpers come from `@jac/runtime` (`Router, Routes, Route, Link,
  useNavigate, jacLogin, jacSignup, AuthGuard`). npm packages are listed in jac.toml
  and imported as `import from "pkg" { X }`.
- Dev server: `jac start --dev main.jac`. Kill stale servers first
  (`pkill -f "jac start"`).
