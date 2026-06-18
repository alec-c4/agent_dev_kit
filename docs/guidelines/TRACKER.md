# Work items and trackers

Agent Dev Kit is **tracker-agnostic**. Specs and plans live in `.ai/` in the target project — that is the **source of truth**. Linear, Jira, GitHub Issues, or no tracker at all are supported.

See also [SPECS.md](SPECS.md) and [WORKFLOW.md](WORKFLOW.md).

## Core concepts

| Term | Meaning | Example |
|------|---------|---------|
| **work_ref** | ID of the **current task** you are working on now | `GH-58`, `LIN-ENG-123`, `JIRA-PROJ-456`, `adhoc-export-csv` |
| **spec_key** | Stable key for a **spec lineage** (one feature area) | `export-csv`, `GH-42` (if team uses primary ticket as key) |
| **Tracker link** | Optional URL to the external ticket | `https://linear.app/team/issue/ENG-123` |

**Rule:** fix and update tasks **edit the existing spec** for the same `spec_key`. They do not fork a second spec file. Plans and verification for the **current** task use `work_ref` in the filename.

### Feature vs fix (CSV export scenario)

| Task | work_ref | spec_key | Spec file (recommended) |
|------|----------|----------|-------------------------|
| New export feature | `GH-42` | `export-csv` | `.ai/specs/export-csv-spec.md` v1.0 |
| UTF-8 bugfix | `GH-58` | `export-csv` | same spec → v1.1 |
| Plan for bugfix | `GH-58` | — | `.ai/work/GH-58-plan.md` |

Legacy GitHub-numeric naming (`.ai/issue-42-spec.md`) remains valid — see [Naming](#naming).

## Source of truth

```
External tracker (optional)     .ai/ in repo (canonical)
        │                              │
        │  paste / export / API        │  spec, plan, verification
        └──────── intake ─────────────►│
                                       ▼
                              Agent reads spec + diff
```

The tracker owns **status and human discussion**. It does **not** drive agent workflow unless you explicitly ask. Phase 2 may add optional **projection** (post PR link to ticket) — never make the tracker the control plane.

## Intake ladder (no MCP required)

Use the highest step available. **Do not call tracker APIs** unless a human or an installed tool provides access.

| Step | When | Action |
|------|------|--------|
| 1. **Paste** | Always works | Copy ticket title + body into `.ai/work/{work_ref}-analysis.md` |
| 2. **Single fetch** | Phase 2 — one task by ref | `intake-work-item.sh GH-58` → analysis (preferred over full list) |
| 3. **CLI** | GitHub + `gh` installed | `gh issue view 42` → save to analysis |
| 4. **Cache snapshot** | Phase 2 — many active tasks | Refresh `.ai/tracker-cache.json` — see [Optional tracker cache](#optional-tracker-cache) |
| 5. **Export** | Team exports CSV/JSON | Human drops file; agent reads path noted in analysis |
| 6. **MCP / API** | Optional, Phase 2+ | Skill or integration — same output: analysis file in `.ai/` |

If there is no ticket: use `work_ref: adhoc-{short-slug}` and proceed with [task-* naming](#naming-without-a-tracker).

### Analysis file minimum

```markdown
# Analysis: [title]

**Work ref:** GH-58
**Spec key:** export-csv (existing feature)
**Tracker link:** https://github.com/org/repo/issues/58
**Source:** pasted from Linear / GitHub / chat

## Problem
…

## Affected areas
…
```

## Naming

### Recommended (tracker-agnostic)

```
.ai/
  tracker.yaml                 # optional project config
  tracker-cache.json           # optional Phase 2 — active items index (gitignore)
  specs/
    export-csv-spec.md         # current spec (spec_key)
  archive/
    export-csv-spec.v1.0.md
  work/
    GH-42-analysis.md
    GH-42-plan.md
    GH-58-analysis.md
    GH-58-plan.md
    GH-58-verification.md
  pr-summary.md
```

Sanitize `work_ref` for paths: uppercase → keep; `/` and spaces → `-` (e.g. `LIN-ENG-123` → `LIN-ENG-123`).

### Legacy (GitHub numeric)

```
.ai/
  issue-42-spec.md             # spec_key tied to issue number
  issue-58-plan.md
  archive/issue-42-spec.v1.0.md
```

Supported for existing projects. New work should prefer `specs/` + `work/` when possible.

### Naming without a tracker

```
.ai/
  task-analysis.md
  task-spec.md
  task-plan.md
  task-verification.md
```

Use when the human opts out of ticket IDs. Set `work_ref: adhoc` in spec header.

## work_ref formats

| Tracker | Suggested format | Example |
|---------|------------------|---------|
| GitHub Issues | `GH-{n}` or `#{n}` in header only | `GH-42` |
| Linear | `LIN-{team}-{n}` or org convention | `LIN-ENG-123` |
| Jira | `JIRA-{project}-{n}` | `JIRA-PROJ-456` |
| None / chat | `adhoc-{slug}` | `adhoc-export-csv` |

Pick one convention per project in `.ai/tracker.yaml`. Consistency matters more than the prefix.

## Optional project config

`.ai/tracker.yaml` in the **target app repo** (not in kit registry):

```yaml
# docs/examples/tracker.yaml.example
provider: none        # none | github | linear | jira
work_ref_format: "GH-{n}"
spec_filename: specs/{spec_key}-spec.md
work_filename: work/{work_ref}-{kind}.md
url_template: "https://github.com/org/repo/issues/{id}"
```

Agents read this file during Analyze when present. If missing, use defaults from this document.

## Optional tracker cache (Phase 2)

A **local snapshot of active work items** helps match `work_ref` to title and status when the human says «take ENG-77» without pasting the ticket. It is **optional** and **not** required for spec-first workflow.

### What to cache

| Include | Exclude |
|---------|---------|
| `work_ref`, external id, **title**, **status**, url | Full description / comments (→ fetch one item into analysis) |
| Active / in-progress items only (typ. 20–50) | Entire backlog, closed history |
| `synced_at` timestamp | Stale cache treated as hint only |

**Do not** commit the cache to git — it goes stale quickly. Add to project `.gitignore`:

```gitignore
.ai/tracker-cache.json
```

### Schema (example)

See [docs/examples/tracker-cache.json.example](../examples/tracker-cache.json.example):

```json
{
  "version": 1,
  "synced_at": "2026-06-18T12:00:00Z",
  "provider": "github",
  "items": [
    {
      "work_ref": "GH-58",
      "external_id": "58",
      "title": "CSV export empty on filtered index",
      "status": "open",
      "url": "https://github.com/org/app/issues/58"
    }
  ]
}
```

### How agents use it

```
sync-tracker-cache.sh (on demand)
        ↓
.ai/tracker-cache.json     ← index: id, title, status
        ↓
Human: "work on GH-58"
        ↓
Agent resolves title/status/url from cache
        ↓
intake-work-item.sh GH-58  ← still writes full work/GH-58-analysis.md
```

The cache **resolves references**; **analysis + spec** remain the contract. Never skip analysis because a row exists in the cache.

### When you need it

| Situation | Cache |
|-----------|-------|
| One task, paste each time | Skip |
| «Pick up ENG-77» without paste | Useful |
| Many parallel branches | Useful — avoid closed/wrong id |
| No tracker | Not applicable |

### When you do not need it

- Adhoc / `task-*` workflow
- Team always pastes ticket body into analysis
- Phase 1.5 paste-only is enough

### Phase 2 scripts

| Script | Purpose |
|--------|---------|
| `scripts/intake-work-item.sh` | Fetch **one** item → `work/{ref}-analysis.md` (paste, `gh issue view`) |
| `scripts/sync-tracker-cache.sh` | *(planned)* Write `.ai/tracker-cache.json` |

**Priority:** single-item intake before full-list sync. Cache is a convenience layer, not source of truth.

## Branches, commits, PRs

Include `work_ref` where humans search:

- Branch: `feature/GH-42-export-csv` or `fix/GH-58-csv-utf8`
- PR title: `fix(api): UTF-8 BOM in CSV export (GH-58)`
- PR body: link tracker URL; reference spec version and AC IDs

Spec content does not depend on which tracker you use.

## Phase 2 automation

| Component | Status | Purpose |
|-----------|--------|---------|
| `skills/work-intake/` | shipped | Parse work_ref; suggest `.ai/` paths; run intake script |
| `scripts/intake-work-item.sh` | shipped | One task → `work/{ref}-analysis.md` (paste, gh view) |
| `skills/resolve-task/` | shipped | Full pipeline from work_ref |
| `scripts/sync-tracker-cache.sh` | planned | Optional snapshot → `.ai/tracker-cache.json` |
| `skills/tracker-sync/` | planned | Optional projection: spec summary → ticket comment |

## Quick decision tree

1. **Ticket exists?** → set `work_ref`, paste into `work/{ref}-analysis.md`
2. **Same feature as before?** → find spec by `spec_key`; bump version for fix/update
3. **New feature?** → new spec v1.0 with new `spec_key`
4. **No ticket?** → `task-*` or `adhoc-{slug}`
5. **Many ids / no paste?** → Phase 2: optional `tracker-cache.json`, then single-item intake
6. **MCP/API?** → optional; never block workflow without it
