---
name: spec-lint
description: Periodic health check across .ai/specs/ — stale drafts, broken related_spec_key links, unresolved clarifications, orphaned archives. Use when user runs /spec-lint or asks to audit specs for contradictions or staleness.
user-invocable: true
---

# Spec lint workflow

**Explicit invoke** — skip [intent-router](../intent-router/SKILL.md) classification.

## Intent

Audit the **whole** `.ai/specs/` tree for bookkeeping rot that a single-task verifier never checks (verifier only reads the spec touched by the current diff). This is a periodic health check, not a per-PR gate — do not block commits on it.

## Scope

Read, don't guess:

- `.ai/specs/*-spec.md` (current specs) and legacy `.ai/issue-*-spec.md`
- `.ai/archive/*-spec.v*.md`
- `.ai/index.md` if present ([SPECS.md](../../docs/guidelines/SPECS.md#index-and-log))

## Checks

| # | Check | Flag when |
|---|-------|-----------|
| 1 | Stale draft | `status: draft` with no Changelog entry in the last active work session, or draft with implementation already merged |
| 2 | Unresolved clarification | `[NEEDS CLARIFICATION]` still present in Open questions |
| 3 | Broken cross-reference | `related_spec_key` / `Supersedes` points to a spec_key with no matching file (current or archive) |
| 4 | One-directional link | Spec A references B via `related_spec_key`, but B has no back-reference to A |
| 5 | Orphaned archive | `.ai/archive/{key}-spec.v{n}.md` exists but current `.ai/specs/{key}-spec.md` has no Changelog row mentioning `v{n}` supersession |
| 6 | AC drift | Spec has ACs with no `*(added|modified|removed vX)*` tag despite a version > 1.0 — version bumped but AC annotations missing |
| 7 | Missing index entry | `.ai/index.md` exists but a spec file has no corresponding row |

## Output format

```markdown
# Spec lint: [date]

**Scope:** .ai/specs/ (N files), .ai/archive/ (M files)

## Findings

| # | Check | Spec key | Detail |
|---|-------|----------|--------|
| 1 | stale-draft | export-csv | draft since v1.0, no activity, code already merged in #123 |

## Clean

- [spec_key list with no findings]
```

Report only — **do not edit specs** to fix findings; hand the list back to the human or the owning writer agent.

## First message

Announce: **Running spec-lint** per skills/spec-lint/SKILL.md — read-only audit, not a commit gate.

## Do not

- Treat lint findings as blockers for the current task's verification/review gates — those stay scoped to the diff.
- Auto-edit specs to resolve findings.
