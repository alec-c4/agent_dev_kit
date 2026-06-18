---
name: resolve-task
description: Full task pipeline from work_ref or pasted ticket — intake, classify feature vs fix, spec, plan, TDD, verification. Use with /resolve-task GH-58 or resolve this ticket.
user-invokable: true
---

# Resolve task

End-to-end pipeline for **one work item**. Explicit invoke — skip generic [intent-router](../intent-router/SKILL.md) unless feature vs fix is unclear after intake.

Same artifacts as `/feature` or `/fix` plus mandatory intake. See [TRACKER.md](../../docs/guidelines/TRACKER.md) and [WORKFLOW.md](../../docs/guidelines/WORKFLOW.md).

## Arguments

User may pass:

- **work_ref** — `GH-58`, `LIN-ENG-123`, `adhoc-export-csv`
- **Pasted ticket** — with or without ref (infer or ask once)
- **Intent hint** — «fix», «feature», «bug» (optional)

If **work_ref** missing, ask **one** question to obtain it or use `adhoc-{slug}`.

## Pipeline

### Phase A — Intake (mandatory)

1. Load [work-intake](../work-intake/SKILL.md) protocol.
2. Write `.ai/work/{work_ref}-analysis.md`:
   - Paste: `./scripts/kit intake {work_ref} --paste`
   - Or fetch: `./scripts/kit intake {work_ref}` when `gh` available
3. Set **spec_key** in analysis header (existing lineage or new slug).

### Phase B — Classify (feature vs fix)

| Signal | Workflow |
|--------|----------|
| Bug, regression, broken | [fix](../fix/SKILL.md) |
| New capability, extend feature | [feature](../feature/SKILL.md) |
| Unclear | **One** question: fix vs feature vs investigate-only |

Then follow the chosen workflow **without re-classifying**.

### Phase C — Spec → plan → implement → ship

Execute all gates from the chosen workflow:

1. **Spec** — approve before plan/code ([SPECS.md](../../docs/guidelines/SPECS.md))
2. **Plan** — `.ai/work/{work_ref}-plan.md`; approve before production code
3. **Branch** — `feature/` or `fix/` per [GIT.md](../../docs/guidelines/GIT.md)
4. **TDD** — [TESTING.md](../../docs/guidelines/TESTING.md) + stack profile
5. **Comprehension** — when tier ≥ standard ([comprehension-check](../comprehension-check/SKILL.md), [COMPREHENSION.md](../../docs/guidelines/COMPREHENSION.md))
6. **Verification** — **new agent session** ([VERIFICATION.md](../../docs/guidelines/VERIFICATION.md))
7. **Review** — [REVIEW.md](../../docs/guidelines/REVIEW.md)
8. **PR** — `.ai/pr-summary.md`; confirm before push ([ship](../ship/SKILL.md) checklist)

Run `./scripts/kit detect-stack --write-profile` after intake if stack unknown.

## First message

```markdown
**Resolve task** — work_ref: {ref}
1. Intake → `.ai/work/{ref}-analysis.md`
2. {feature|fix} workflow → spec → plan → TDD → verify → PR
```

## Do not

- Skip intake when a ticket id was given.
- Implement before spec approval (non-trivial work).
- Auto-merge or deploy without human confirm.
