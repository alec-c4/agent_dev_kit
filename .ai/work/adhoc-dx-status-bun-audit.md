# Audit: unused / dead assets

**Work ref:** adhoc-dx-status-bun  
**Date:** 2026-07-31  
**Checkpoint tag:** `checkpoint/pre-dx-status-bun`

## Summary

Hard DELETE candidates are few. Skills/packs/agents/hooks are wired. Main cleanup is thin configure wrappers + Bun migration of Python/Ruby.

## DELETE (done 2026-07-31)

| Path | Notes |
|------|-------|
| `scripts/configure-cursor-attribution.sh` | Removed |
| `scripts/configure-settings.sh` | Removed — use `kit configure` |
| `scripts/configure-attribution.sh` | Removed — use `kit configure` |

## Docs fix (done)

| Issue | Action |
|-------|--------|
| INTENT-ROUTING `commands/resolve-task.md` | Pointed at `skills/resolve-task/SKILL.md` |

## KEEP

All `scripts/kit` commands, detect/intake/validate/compile/deploy*, fixtures, packs (including overlap), agents, hooks, templates, `registry/dod.yaml` universal ids.

## Bun migration entry points

See plan: `detect_stack.py`, configure/sync libs, inline python in intake/sync-tracker/validate-handoff/detect-shell, Ruby YAML in `compile_registry.sh` + `validate-skills.sh`.
