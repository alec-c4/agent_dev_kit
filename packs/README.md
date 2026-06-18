# Stack packs — optional skill bundles per technology

Install subsets with `./scripts/kit install --pack=core,rails` or deploy after install:

```bash
./scripts/kit deploy-skills --pack=rails --scope=project
```

| Pack | ID | Skills | Use when |
|------|-----|--------|----------|
| Universal Core | `core` | 26 | Always — stack profiles + workflow |
| Stack Patterns | `patterns` | 15 | All framework pattern skills |
| Cross-cutting Topics | `topics` | 4 | Security, LLM, RAG, MCP |
| Rails | `rails` | 5 | Rails / Hotwire / Inertia projects |
| Frontend / Node | `node` | 4 | Next.js, Nuxt, SvelteKit, Svelte |
| Python | `python` | 2 | Django, FastAPI |
| Go | `go` | 1 | Go services |
| Elixir | `elixir` | 1 | Phoenix / LiveView |

**Default install** deploys `core`, `patterns`, and `topics`. Stack packs are optional slices of `patterns` for smaller installs.

Community packs: [community/README.md](community/README.md).

## depends_on

Manifests list `depends_on: [core]`. `deploy-skills.sh` installs dependencies first.

## Add a pack

See [docs/EXTENDING.md](../docs/EXTENDING.md) and [community/_template/](community/_template/).
