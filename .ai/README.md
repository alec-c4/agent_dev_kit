# Planning artifacts

The `.ai/` directory holds **session planning files for the target project**, not for the Agent Dev Kit repository itself.

## Convention

```
.ai/
  issue-42-analysis.md    # Issue exploration and codebase notes
  issue-42-spec.md        # Current spec (document version in header)
  archive/
    issue-42-spec.v1.0.md # Superseded versions
  issue-42-plan.md        # Implementation plan (references spec AC IDs)
  issue-42-verification.md # Verifier agent: tests, lint, docs sync
  pr-summary.md           # Draft PR description
  task-analysis.md        # Ad-hoc tasks without issue numbers
  task-spec.md
  task-plan.md
  task-verification.md
```

## Gitignore

Recommended for application repos:

```gitignore
.ai/
```

Teams that want shared specs and plans in git may commit `.ai/` intentionally — document that choice in the project README.

## Workflow

1. **Analyze** → write `*-analysis.md`
2. **Spec** → new v1.0 or bump version for fix/update — [SPECS.md](../docs/guidelines/SPECS.md)
3. **Plan** → write `*-plan.md`, get human approval
4. **Implement** → TDD; tests trace to spec AC IDs
5. **Verify** → separate agent: [VERIFICATION.md](../docs/guidelines/VERIFICATION.md) → save `*-verification.md`
6. **Review** → [REVIEW.md](../docs/guidelines/REVIEW.md)
7. **PR** → copy from `pr-summary.md`

## Kit repo note

Implementation plans for **kit development** live outside this repo (for example `~/.cursor/plans/agent_dev_kit-implementation.plan.md`).
