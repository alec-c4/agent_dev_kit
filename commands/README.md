# Kit workflow commands (Phase 2)

Canonical workflow shortcuts live as **skills** under `skills/{name}/SKILL.md` (`user-invocable: true`).

| File | Slash (Claude Code / Codex) | Intent |
|------|----------------------------|--------|
| [feature](../skills/feature/SKILL.md) | `/feature` or `$feature` | New or updated capability |
| [fix](../skills/fix/SKILL.md) | `/fix` | Bug fix |
| [plan](../skills/plan/SKILL.md) | `/plan` | Plan only (after approved spec) |
| [review](../skills/review/SKILL.md) | `/review` | Pre-commit / PR review |
| [ship](../skills/ship/SKILL.md) | `/ship` | PR summary and ship checklist |

Install deploys skills via `./scripts/kit deploy-skills --pack=core`. Antigravity workflows: `./scripts/kit deploy-workflows`.

Plain text uses [intent-router](../skills/intent-router/SKILL.md) — same pipeline, no slash required.
