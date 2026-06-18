# Installation guide

Install Agent Dev Kit into your AI tools and optionally into a project repo.

**Prerequisites:** bash, `jq` (recommended), Python 3 with PyYAML for `./scripts/kit compile`.

## 1. Get the kit

```bash
git clone https://github.com/alec-c4/agent_dev_kit.git ~/Projects/agent_dev_kit
cd ~/Projects/agent_dev_kit
```

## 2. Preview install

```bash
./scripts/kit install --dry-run --target=all
```

## 3. Global install (recommended first)

```bash
./scripts/kit install --target=all
```

| Target | What it configures |
|--------|-------------------|
| `cursor` | `~/.cursor/agent_dev_kit` link + `kit-*.mdc` rules |
| `claude` | `~/.claude/` — AGENTS.md, CLAUDE.md, agents, docs |
| `codex` | `~/.codex/AGENTS.md` + kit tree |
| `antigravity` | `~/.gemini/AGENTS.md` + GEMINI.md |
| `both` | Claude + Cursor |
| `all` | All four tools |

Restart your IDE or CLI after install.

## 4. Project install

From your **application repo** (not the kit repo):

```bash
/path/to/agent_dev_kit/scripts/kit install --target=all --project
```

Deploys `AGENTS.md`, `.agents/skills/`, `.cursor/rules/`, and `.ai/` scaffold into the current directory.

## 5. Skill packs

Default install deploys **core**, **patterns**, and **topics**. See [packs/README.md](../packs/README.md).

| Goal | Command |
|------|---------|
| Full kit (default) | `./scripts/kit install --target=all` |
| Minimal + Rails only | `./scripts/kit install --target=all --pack=core,rails` |
| Everything including stack slices | `./scripts/kit install --target=all --pack=all` |
| Deploy one pack later | `./scripts/kit deploy-skills --pack=rails --scope=project` |

Stack packs (`rails`, `node`, `python`, `go`, `elixir`) are subsets of pattern skills for smaller installs.

## 6. Hooks (opt-in)

```bash
./scripts/kit install --target=both --with-hooks
./scripts/kit install --target=both --with-hooks --with-review-gate
```

See [hooks.md](hooks.md).

## 7. Verify

```bash
./scripts/kit compile
./scripts/kit validate --phase=1
./scripts/kit detect-stack --write-profile   # from an app repo
```

## 8. Use in a session

1. Open a project with `AGENTS.md` (project install) or rely on global adapters.
2. The assistant reads [AGENTS.md](../AGENTS.md) → [docs/guidelines/](guidelines/).
3. Run `./scripts/kit detect-stack` when stack tooling is unknown.

## Related docs

- [tool-adapters.md](tool-adapters.md) — paths and merge order per tool
- [shell-commands.md](shell-commands.md) — `./scripts/kit` reference
- [EXTENDING.md](EXTENDING.md) — add stacks, topics, community packs
