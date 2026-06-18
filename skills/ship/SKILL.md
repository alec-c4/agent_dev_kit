---
name: ship
description: Prepare PR summary and ship checklist — confirm before push or merge. Use when user runs /ship or asks to open or prepare a pull request.
user-invokable: true
---

# Ship workflow

**Explicit invoke** — skip [intent-router](../intent-router/SKILL.md) classification.

## Intent

**Ship / PR** — draft summary, test plan, and merge checklist. **External side effects require explicit human confirm.**

## Prerequisites

- Verification passed ([VERIFICATION.md](../../docs/guidelines/VERIFICATION.md)).
- Review complete ([REVIEW.md](../../docs/guidelines/REVIEW.md)) when DoD requires it.

## Steps

1. Confirm human wants to **push**, **open PR**, or **merge** — do not infer from vague «ship it».
2. Draft `.ai/pr-summary.md`:
   - What changed and why
   - Spec / work_ref links
   - Test plan checklist
   - Breaking changes or migration notes
3. Suggest PR title (conventional commit style per [COMMITS.md](../../docs/guidelines/COMMITS.md)).
4. Run `./scripts/kit validate --phase=1` if kit repo changed.
5. Open PR or provide `gh pr create` body — **only after human confirms**.

## First message

Announce: **Following ship workflow** — will draft PR summary; confirm before push or merge.

## Do not

- Push, merge, or deploy without explicit human approval.
- Force-push `main`/`master` unless human explicitly requests.
