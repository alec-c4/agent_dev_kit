# Antigravity adapter

This repository is **[Agent Dev Kit](AGENTS.md)** — an LLM-agnostic developer kit.

Antigravity loads `GEMINI.md` and `AGENTS.md` at session start. **In Antigravity, this file overrides conflicting rules in AGENTS.md.** Universal workflow stays in [docs/guidelines/](docs/guidelines/).

## Quick routing

1. Read [AGENTS.md](AGENTS.md) for workflow and guidelines index.
2. **Plain text** → [intent-router](skills/intent-router/SKILL.md) or [INTENT-ROUTING.md](docs/guidelines/INTENT-ROUTING.md).
3. **Workflow slash** → `.agents/workflows/*.md` (table below) — same pipeline as NL.
4. Non-trivial task: spec first — [docs/guidelines/SPECS.md](docs/guidelines/SPECS.md).
5. Detect stack: `./scripts/kit detect-stack --write-profile` → load `skills/stacks/<id>/`.
6. Task complete → verifier session — [docs/guidelines/VERIFICATION.md](docs/guidelines/VERIFICATION.md).

## Workflows

Deployed to `./.agents/workflows/` via `./scripts/kit install --target=antigravity --project` or `./scripts/kit deploy-workflows`.

| Workflow | Source | Same as Claude |
|----------|--------|----------------|
| `feature` | [skills/feature/SKILL.md](skills/feature/SKILL.md) | `/feature` |
| `fix` | [skills/fix/SKILL.md](skills/fix/SKILL.md) | `/fix` |
| `plan` | [skills/plan/SKILL.md](skills/plan/SKILL.md) | `/plan` |
| `review` | [skills/review/SKILL.md](skills/review/SKILL.md) | `/review` |
| `ship` | [skills/ship/SKILL.md](skills/ship/SKILL.md) | `/ship` |
| `resolve-task` | [skills/resolve-task/SKILL.md](skills/resolve-task/SKILL.md) | `/resolve-task` |

Codex uses `$feature`, `$resolve-task`, … from `.agents/skills/` after `./scripts/kit deploy-skills --pack=core`.

**Intake:** `./scripts/kit intake <work_ref> --paste` before spec when using tickets.

## Antigravity-specific

- **Manager vs Editor:** use Manager for parallel or long-running tasks; Editor for synchronous edits. Hand off with clear artifacts in `.ai/`.
- **Browser verify (optional):** for UI work, verify in the built-in browser when available — do not skip spec or verification gates.

## Defer

Follow the developer's global rules when stricter. Do not duplicate Cursor user rules or shell syntax preferences here.

See [docs/tool-adapters.md](docs/tool-adapters.md) for install paths and skill locations.
