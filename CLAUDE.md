# Claude Code adapter

This repository is **[Agent Dev Kit](AGENTS.md)** — an LLM-agnostic developer kit.

Claude Code loads `CLAUDE.md` automatically. **Canonical instructions:** [AGENTS.md](AGENTS.md) and [docs/guidelines/](docs/guidelines/).

## Quick routing

1. Read [AGENTS.md](AGENTS.md) for workflow and guidelines index.
2. **Plain text** → [intent-router](skills/intent-router/SKILL.md) or [INTENT-ROUTING.md](docs/guidelines/INTENT-ROUTING.md).
3. **Slash command** → same pipeline, skip classify (table below).
4. Non-trivial task: write `.ai/*-spec.md` first — [docs/guidelines/SPECS.md](docs/guidelines/SPECS.md).
5. Detect stack: `./scripts/kit detect-stack --write-profile` → load `skills/stacks/<id>/`.
6. Follow [docs/guidelines/WORKFLOW.md](docs/guidelines/WORKFLOW.md).
7. Task complete → **verifier agent** (new session): [docs/guidelines/VERIFICATION.md](docs/guidelines/VERIFICATION.md).

## Slash commands

Installed to `~/.claude/commands/` and `~/.claude/skills/` via `./scripts/kit install --target=claude` (or `--target=all`).

| Command | Skill source | Workflow |
|---------|--------------|----------|
| `/feature` | [skills/feature/SKILL.md](skills/feature/SKILL.md) | Spec → plan → TDD → comprehension → verify → review → PR |
| `/fix` | [skills/fix/SKILL.md](skills/fix/SKILL.md) | Analyze → spec bump → TDD fix → verify → PR |
| `/plan` | [skills/plan/SKILL.md](skills/plan/SKILL.md) | Plan only (approved spec required) |
| `/review` | [skills/review/SKILL.md](skills/review/SKILL.md) | [REVIEW.md](docs/guidelines/REVIEW.md) checklist |
| `/ship` | [skills/ship/SKILL.md](skills/ship/SKILL.md) | PR summary — confirm before push/merge |
| `/resolve-task` | [skills/resolve-task/SKILL.md](skills/resolve-task/SKILL.md) | Intake → feature/fix pipeline end-to-end |

Natural language uses the **same steps** — commands bypass intent classification only.

**Intake:** `./scripts/kit intake GH-58 --paste` — see [TRACKER.md](docs/guidelines/TRACKER.md).

## Permissions

You may create, edit, or delete files in the current project without asking, unless the user's rules require confirmation for destructive actions. Never modify files outside the project directory.
