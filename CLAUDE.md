# Claude Code adapter

This repository is **[Agent Dev Kit](AGENTS.md)** — an LLM-agnostic developer kit.

Claude Code loads `CLAUDE.md` automatically. **Canonical instructions:** [AGENTS.md](AGENTS.md) and [docs/guidelines/](docs/guidelines/).

## Quick routing

1. Read [AGENTS.md](AGENTS.md) for workflow and guidelines index.
2. Non-trivial task: write `.ai/*-spec.md` first — [docs/guidelines/SPECS.md](docs/guidelines/SPECS.md).
3. Detect stack: `./scripts/kit detect-stack --write-profile` → load `skills/stacks/<id>/`.
4. Follow [docs/guidelines/WORKFLOW.md](docs/guidelines/WORKFLOW.md).
5. Task complete → **verifier agent** (new session): [docs/guidelines/VERIFICATION.md](docs/guidelines/VERIFICATION.md).

## Permissions

You may create, edit, or delete files in the current project without asking, unless the user's rules require confirmation for destructive actions. Never modify files outside the project directory.

## Claude Code extras (Phase 2+)

When installed to `~/.claude/`, slash commands (`/feature`, `/fix`, `/review`, …) encode the same workflows as the guidelines.

Until then, follow guidelines directly.
