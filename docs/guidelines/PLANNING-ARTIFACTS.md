# Planning artifacts

The contract for a project's `.ai/` directory. It lives here, in the kit's
tracked docs, because `.ai/` itself is session state the kit never commits.

The `.ai/` directory holds **session planning files for the target project**, not for the Agent Dev Kit repository itself.

See [TRACKER.md](TRACKER.md) for `work_ref`, `spec_key`, tracker-agnostic intake, and optional `.ai/tracker.yaml`.

Optional project kit config: `.ai/kit.yaml` — `spec_language`, `process_references` (default `omit`), `gates`. Example: [docs/examples/kit.yaml.example](../examples/kit.yaml.example).

## Naming (recommended)

| Artifact | Path pattern | Key field |
|----------|--------------|-----------|
| Tracker config | `.ai/tracker.yaml` | optional |
| Tracker cache | `.ai/tracker-cache.json` | optional Phase 2 — id, title, status index |
| Spec (current) | `.ai/specs/{spec_key}-spec.md` | spec_key |
| Spec archive | `.ai/archive/{spec_key}-spec.v{X}.md` | spec_key |
| Analysis | `.ai/work/{work_ref}-analysis.md` | work_ref |
| Plan | `.ai/work/{work_ref}-plan.md` | work_ref |
| Findings | `.ai/work/{work_ref}-findings.md` | work_ref — feedback ledger |
| Lessons | `.ai/lessons.md` | project; prefer commit |
| Handoff | `.ai/work/{work_ref}-handoff.md` | work_ref — comprehension gate |
| Verification | `.ai/work/{work_ref}-verification.md` | work_ref |
| PR draft | `.ai/pr-summary.md` | — |
| Spec index (optional) | `.ai/index.md` | requires `wiki_index: true` in `.ai/kit.yaml` |
| Event log (optional) | `.ai/log.md` | requires `wiki_index: true` in `.ai/kit.yaml` |

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
  kit.yaml
  tracker.yaml
  index.md            # optional — wiki_index: true
  log.md               # optional — wiki_index: true
  specs/export-csv-spec.md
  archive/export-csv-spec.v1.0.md
  work/GH-42-analysis.md
  work/GH-58-plan.md
  work/GH-58-handoff.md
  work/GH-58-verification.md
  pr-summary.md
```

See [SPECS.md § Index and log](SPECS.md#index-and-log) for when `wiki_index` is worth turning on.

## Gitignore

Recommended for application repos:

```gitignore
.ai/
```

If the team commits `.ai/` intentionally, still gitignore machine-local cache:

```gitignore
.ai/tracker-cache.json
```

See [TRACKER.md](TRACKER.md#optional-tracker-cache-phase-2).

## Workflow

1. **Analyze** → `work/{work_ref}-analysis.md` (paste ticket if no API)
2. **Spec** → new v1.0 or bump by spec_key — [SPECS.md](SPECS.md)
3. **Plan** → `work/{work_ref}-plan.md`, get human approval
4. **Implement** → TDD; tests trace to spec AC IDs
5. **Comprehension** → [COMPREHENSION.md](COMPREHENSION.md) → `work/{work_ref}-handoff.md`
6. **Verify** → [VERIFICATION.md](VERIFICATION.md) → `work/{work_ref}-verification.md`
7. **Review** → [REVIEW.md](REVIEW.md)
8. **PR** → copy from `pr-summary.md`

## Kit repo note

Implementation plans for **kit development** live outside this repo (for example `~/.cursor/plans/agent_dev_kit-implementation.plan.md`).
