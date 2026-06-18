# Contributing to Agent Dev Kit

Thank you for improving the kit. This repo is configuration and documentation for **AI-assisted development** (Cursor, Claude Code, Copilot, and others) — not an application runtime.

**Canonical entry:** [AGENTS.md](AGENTS.md). [CLAUDE.md](CLAUDE.md) is a Claude Code adapter only.

## Before you open a PR

```bash
# After editing registry/*.yaml
bash scripts/compile_registry.sh

# Registry validation
bash scripts/validate-registry.sh --phase=1

# Preview install
bash scripts/install.sh --dry-run --target=both
```

CI (Phase 5+) will run [.github/workflows/validate.yml](.github/workflows/validate.yml).

## What to change where

| Change | Location |
|--------|----------|
| Cross-cutting workflow, review, commits | `docs/guidelines/*.md` (stack-agnostic) |
| Stack tooling, DoD overlay, skill routing | `skills/stacks/<id>/profile.yaml` |
| Detection signals only | `registry/stacks.yaml` → `stack_skill` |
| Universal Definition of Done | `registry/dod.yaml` |
| Tool adapters | `AGENTS.md` (canonical), `CLAUDE.md` (Claude Code), `templates/cursor/rules/` |
| Framework patterns | `skills/<name>/` packs — **not** guidelines |
| Slash commands, agents, hooks | Phase 2+ |

See [docs/EXTENDING.md](docs/EXTENDING.md) and [docs/architecture.md](docs/architecture.md).

**Implementation plans** for kit development live outside this repo (for example `~/.cursor/plans/`), not in git.

## Rules

- **Stack-specific content goes in skills** — not in guidelines, `CLAUDE.md`, or bloated registry YAML.
- New stack: add `skills/stacks/<id>/` + detection line in `registry/stacks.yaml`.
- Run `compile_registry.sh` after editing `registry/*.yaml` or `skills/stacks/*/profile.yaml`.
- No secrets, API keys, or machine-specific paths in committed files.
- Keep PRs focused — one concern per PR when possible.
- **Personal CLAUDE.md additions** (auto-injected blocks from third-party tools, private MCP workflows, `<!-- tool:start/end -->` markers) must not be committed to the repo. They belong in a local-only file outside the kit, or behind a gitignore. The committed `CLAUDE.md` must stay universally applicable.

## Install locally

```bash
bash scripts/install.sh --dry-run --target=both
bash scripts/install.sh --target=cursor
bash scripts/install.sh --target=claude
bash scripts/install.sh --target=both --project   # current repo
```

## Questions

Open an issue with the label `question` or describe your use case in the PR body.
