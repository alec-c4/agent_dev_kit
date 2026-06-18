# Planning artifacts

The `.ai/` directory holds **session planning files for the target project**, not for the Agent Dev Kit repository itself.

See [TRACKER.md](../docs/guidelines/TRACKER.md) for `work_ref`, `spec_key`, tracker-agnostic intake, and optional `.ai/tracker.yaml`.

## Naming (recommended)

| Artifact | Path pattern | Key field |
|----------|--------------|-----------|
| Tracker config | `.ai/tracker.yaml` | optional |
| Tracker cache | `.ai/tracker-cache.json` | optional Phase 2 — id, title, status index |
| Spec (current) | `.ai/specs/{spec_key}-spec.md` | spec_key |
| Spec archive | `.ai/archive/{spec_key}-spec.v{X}.md` | spec_key |
| Analysis | `.ai/work/{work_ref}-analysis.md` | work_ref |
| Plan | `.ai/work/{work_ref}-plan.md` | work_ref |
| Verification | `.ai/work/{work_ref}-verification.md` | work_ref |
| PR draft | `.ai/pr-summary.md` | — |

**work_ref** — current task ID (`GH-58`, `LIN-ENG-123`, `adhoc-slug`).  
**spec_key** — stable feature lineage (`export-csv`); fix/update edits the same spec file.

## Legacy (GitHub numeric)

```
.ai/
  issue-42-spec.md
  issue-58-plan.md
  archive/issue-42-spec.v1.0.md
```

Still supported. Prefer `specs/` + `work/` for new projects.

## Without a tracker

```
.ai/
  task-analysis.md
  task-spec.md
  task-plan.md
  task-verification.md
```

## Example layout

```
.ai/
  tracker.yaml
  specs/export-csv-spec.md
  archive/export-csv-spec.v1.0.md
  work/GH-42-analysis.md
  work/GH-58-plan.md
  work/GH-58-verification.md
  pr-summary.md
```

## Gitignore

Recommended for application repos:

```gitignore
.ai/
```

If the team commits `.ai/` intentionally, still gitignore machine-local cache:

```gitignore
.ai/tracker-cache.json
```

See [TRACKER.md](../docs/guidelines/TRACKER.md#optional-tracker-cache-phase-2).

## Workflow

1. **Analyze** → `work/{work_ref}-analysis.md` (paste ticket if no API)
2. **Spec** → new v1.0 or bump by spec_key — [SPECS.md](../docs/guidelines/SPECS.md)
3. **Plan** → `work/{work_ref}-plan.md`, get human approval
4. **Implement** → TDD; tests trace to spec AC IDs
5. **Verify** → [VERIFICATION.md](../docs/guidelines/VERIFICATION.md) → `work/{work_ref}-verification.md`
6. **Review** → [REVIEW.md](../docs/guidelines/REVIEW.md)
7. **PR** → copy from `pr-summary.md`

## Kit repo note

Implementation plans for **kit development** live outside this repo (for example `~/.cursor/plans/agent_dev_kit-implementation.plan.md`).
