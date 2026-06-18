---
name: tracker-sync
description: Optional projection of spec or handoff summary to a tracker ticket comment. Never the control plane.
user-invokable: false
---

# Tracker sync (optional projection)

Post a **short summary** to the external tracker when the human asks. This is **not** source of truth — `.ai/specs/` and `.ai/work/` remain authoritative.

## When to use

- Human says «post handoff to GH-58» or «add PR link to ticket».
- After comprehension gate or before ship — one-way notification only.

## When not to use

- Do not auto-comment without explicit human request.
- Do not replace intake, spec approval, or verification.
- Linear/Jira: paste summary for human unless their CLI/API is configured.

## GitHub (gh)

```bash
# Confirm work_ref and summary with human first
gh issue comment 58 --body "$(cat <<'EOF'
## Agent handoff (GH-58)

- Spec: `.ai/specs/export-csv-spec.md` v1.1
- PR: https://github.com/org/app/pull/120
- Verification: `.ai/work/GH-58-verification.md`

EOF
)"
```

## Rules

- Include `work_ref`, spec version, PR URL, and paths to `.ai/` artifacts.
- No secrets, tokens, or internal-only URLs.
- If `gh` fails, show the draft comment and stop — do not retry with invented APIs.

## Related

- [TRACKER.md](../../docs/guidelines/TRACKER.md) — cache and intake
- [work-intake](../work-intake/SKILL.md) — analysis file is still required
