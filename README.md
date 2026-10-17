# jaseci-skill

A Claude [Agent Skill](https://docs.claude.com/en/docs/agents-and-tools/agent-skills)
for writing **Jac / Jaseci** code that actually compiles: graph programs with
nodes, edges and walkers, byLLM AI functions, REST APIs and full-stack apps.

Jac changes quickly and looks like Python, so models tend to write invalid Jac.
This skill makes Claude:

1. install/check the `jac` CLI (`scripts/ensure_jac.sh`),
2. read the **version-matched** guides built into the CLI (`jac guide ...`)
   before writing code,
3. avoid the errors that most often break first drafts (all found by actually
   compiling code),
4. check its work with `jac check`, `jac run`, `jac test` and `jac start`
   before handing it back.

## Layout

```
jaseci/
├── SKILL.md                      # workflow, guide routing table, pitfalls
├── scripts/ensure_jac.sh         # install jaclang (+ byllm with --with-llm), list guides
├── references/                   # offline fallbacks when the CLI isn't available
│   ├── syntax.md
│   ├── osp.md                    # nodes / edges / walkers
│   ├── byllm.md                  # by llm, sem, MockLLM
│   └── server-and-fullstack.md   # def:pub / walker:pub, jac start, .cl.jac
├── examples/                     # verified on jaclang 0.16.7
│   ├── graph_walker.jac          # jac run
│   ├── llm_functions.jac         # jac test  (needs: pip install byllm)
│   └── api_service/              # jac start main.jac --no_client
└── evals/evals.json              # test prompts for iterating on the skill
```

## Install

**Claude Code (all projects):**
```bash
git clone https://github.com/methulih/jaseci-skill
cp -r jaseci-skill/jaseci ~/.claude/skills/jaseci
```

**Claude Code (one repo, shared with your team):** copy `jaseci/` to
`<your-repo>/.claude/skills/jaseci` and commit it.

**Claude.ai / Claude desktop:** zip the `jaseci/` folder (or use the packaged
`jaseci.skill`) and upload it under *Settings → Capabilities → Skills*.

Then just ask: *"build me a Jac API for ..."*. The skill loads automatically
when Jac/Jaseci comes up.

### Pairs well with

- `jac guide --export .claude/skills`: exports every official Jac guide as
  its own skill (the official, more detailed reference).
- `jac mcp`: an MCP server with live validate/format/run tools.

## Resources

[jaseci.org](https://jaseci.org) ·
[Jac docs](https://jaclang.org/docs/latest) ·
[Jac repo](https://github.com/jaseci-labs/jac) ·
[Jac Hammer](https://jachammer.ai) ([docs](https://docs.jachammer.ai))
