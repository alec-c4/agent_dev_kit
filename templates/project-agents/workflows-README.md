# Project workflows

Antigravity slash workflows in this directory mirror Claude Code `/feature`, `/fix`, etc.

Install:

```bash
./scripts/kit deploy-workflows --scope=project
# or
./scripts/kit install --target=antigravity --project
```

Source of truth: `skills/{feature,fix,plan,review,ship}/SKILL.md` in the kit repo.

Plain text requests use [intent-router](../../skills/intent-router/SKILL.md) or [INTENT-ROUTING.md](../../docs/guidelines/INTENT-ROUTING.md) — same steps as workflows.
