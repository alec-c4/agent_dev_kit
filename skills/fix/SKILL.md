---
name: fix
description: Start bug-fix workflow — analyze, spec bump, TDD fix, verification. Use when user runs /fix or reports a regression or broken behaviour.
user-invokable: true
---

# Fix workflow

**Explicit invoke** — skip [intent-router](../intent-router/SKILL.md) classification. Same pipeline as natural-language bug intent ([INTENT-ROUTING.md](../../docs/guidelines/INTENT-ROUTING.md)).

## Intent

**Bug fix** — reproduce, update spec ACs, fix with TDD, verify.

## Steps

Follow [WORKFLOW.md](../../docs/guidelines/WORKFLOW.md):

1. **Analyze** — set **work_ref** / **spec_key**; document reproduction in `.ai/work/{work_ref}-analysis.md`; detect stack.
2. **Spec** — open spec by **spec_key**; bump version; update or add ACs for the bug ([SPECS.md](../../docs/guidelines/SPECS.md)). **Wait for approval** before code (minimal one-line confirm OK for trivial fixes if human agrees).
3. **Plan** — use **minimal** or **standard** detail in `.ai/work/{work_ref}-plan.md` as appropriate.
4. **Branch** — `fix/<short-name>` per [GIT.md](../../docs/guidelines/GIT.md).
5. **Implement** — failing test first ([TESTING.md](../../docs/guidelines/TESTING.md)).
6. **Comprehension** — when tier ≥ standard ([comprehension-check](../comprehension-check/SKILL.md), [COMPREHENSION.md](../../docs/guidelines/COMPREHENSION.md)).
7. **Verification** — new session ([VERIFICATION.md](../../docs/guidelines/VERIFICATION.md)).
8. **Review** — [REVIEW.md](../../docs/guidelines/REVIEW.md).
9. **PR** — `.ai/pr-summary.md`.

## First message

Announce: **Following fix workflow** (analyze → spec bump → TDD → verification → PR).

## Do not

- «Just fix it» without spec update when ACs or behaviour contract change.
- Commit while verification verdict is FAIL.
