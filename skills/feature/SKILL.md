---
name: feature
description: Start feature workflow — analyze, spec v1.0, plan, TDD, comprehension, verification. Use when user runs /feature or asks to add or build a new capability.
user-invokable: true
---

# Feature workflow

**Explicit invoke** — skip [intent-router](../intent-router/SKILL.md) classification. Same pipeline as natural-language feature intent ([INTENT-ROUTING.md](../../docs/guidelines/INTENT-ROUTING.md)).

## Intent

**Feature (new or update)** — create or bump spec, plan, implement with TDD.

## Steps

Follow [WORKFLOW.md](../../docs/guidelines/WORKFLOW.md) standard feature flow:

1. **Analyze** — read ticket or request; set **work_ref** and **spec_key** ([TRACKER.md](../../docs/guidelines/TRACKER.md)); paste into `.ai/work/{work_ref}-analysis.md` if needed; run `./scripts/kit detect-stack --write-profile`.
2. **Spec** — new task: `.ai/specs/{spec_key}-spec.md` at **v1.0**; update: bump version, changelog, archive ([SPECS.md](../../docs/guidelines/SPECS.md)). **Wait for human approval** before plan or code.
3. **Plan** — `.ai/work/{work_ref}-plan.md` with Detail level (minimal | standard | detailed). **Wait for approval** before production code.
4. **Branch** — `feature/<short-name>` per [GIT.md](../../docs/guidelines/GIT.md).
5. **Implement** — TDD per [TESTING.md](../../docs/guidelines/TESTING.md) and stack profile.
6. **Comprehension** — handoff + Q&A + human sign-off ([COMPREHENSION.md](../../docs/guidelines/COMPREHENSION.md)) when tier ≥ standard.
7. **Verification** — **new agent session** ([VERIFICATION.md](../../docs/guidelines/VERIFICATION.md)); save `.ai/work/{work_ref}-verification.md`.
8. **Review** — [REVIEW.md](../../docs/guidelines/REVIEW.md).
9. **PR** — draft `.ai/pr-summary.md`; open PR with test plan.

## First message

Announce in one line: **Following feature workflow** (spec → plan → TDD → comprehension → verification → review → PR).

If scope is unclear, ask **one** clarifying question before spec — do not skip spec gates.

## Do not

- Commit before spec approval (non-trivial work).
- Skip comprehension or verification when DoD requires them.
- Deploy or merge without explicit human confirm.
