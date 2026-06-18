---
name: intent-router
description: Classify user intent before acting — feature, bug, refactor, audit, or question. Same pipeline for plain text and slash commands; clarify when ambiguous.
user-invokable: true
---

# Intent router

Run **Step 0** on every non-trivial user message before edits, commits, or deploys. Plain text and slash commands (`/feature`, `/fix`, …) share **one pipeline** — see [INTENT-ROUTING.md](../../docs/guidelines/INTENT-ROUTING.md) and [WORKFLOW.md](../../docs/guidelines/WORKFLOW.md).

## When to invoke

- User describes a task in natural language without a slash command.
- Confidence is unclear whether the user wants code, analysis, or an answer.
- Starting a kit workflow from Cursor, Codex (`$intent-router`), or Antigravity (no native `/`).

**Skip classification** when the user already invoked an explicit shortcut (`/feature`, `/fix`, `/review`, `/ship`, `/resolve-task`, or `$feature` in Codex) — map directly to the workflow below.

## Protocol

```
User message
    ↓
Question? → answer only, stop
    ↓
Explicit slash/skill command? → map to workflow, skip classify
    ↓
Classify intent + confidence (high | medium | low)
    ↓
Low → one disambiguation question (2–4 options)
Medium → one-line confirm (intent + spec_key guess + next step)
High → announce workflow + optional hint
    ↓
WORKFLOW.md (spec → plan → TDD → comprehension → verify → review)
```

## Intent → workflow table

| Intent | Signals | Spec | First artifact | Workflow |
|--------|---------|------|----------------|----------|
| **Feature (new)** | add, implement, build, new capability | Create v1.0 | `.ai/work/{work_ref}-analysis.md` → spec v1.0 | Spec → Plan → TDD → Comprehension → Verification → Review → PR |
| **Feature (update)** | extend, change behaviour of existing feature | Bump version | spec bump | Same as feature (new) |
| **Bug (fix)** | broken, regression, error, GH-NN bug | Bump version, update ACs | analysis → spec bump | Analyze → Spec update → Fix → Comprehension → Verification → PR |
| **Refactor** | restructure, rename, no behaviour change | Only if behaviour changes | test baseline | Test baseline → refactor → verify |
| **Audit** | review codebase, security scan, debt report | — | audit report | Scan → Report → Fix plan |
| **Question** | how, why, explain, what does | — | chat answer | Read code, explain — **no commits** |
| **Meta** | list commands, kit help | — | chat answer | Point to AGENTS.md / INTENT-ROUTING.md |

Tracker fields: [TRACKER.md](../../docs/guidelines/TRACKER.md) — set **work_ref** and **spec_key** when a ticket exists.

## Confidence bands

| Confidence | Example | Agent action |
|------------|---------|--------------|
| **High** | «Add CSV export to index», `/fix GH-58` | One-line workflow announcement; proceed to Analyze or Spec |
| **Medium** | «fix export», «improve auth» | One confirm: intent + spec_key guess + next step |
| **Low** | «export broken», «what about CSV?» | One question with 2–4 options (fix / investigate / question) |
| **Question** | «how does export work?» | Answer only — no workflow nudge |

Respect the developer's **request-validation** rule when present: one question, not a questionnaire.

## High-stakes actions (always confirm)

Regardless of entry point, confirm before:

- deploy, release, merge to production
- force-push, destructive git, major dependency bumps
- skipping verification or review when DoD requires them

Do not infer deploy from vague «ship it live».

## Optional command hints

After starting a workflow from plain text (high or medium confidence), you may add **one optional line**:

```markdown
Following **feature workflow** (spec → plan → TDD → verification).
Tip (Claude Code): `/feature` runs the same pipeline explicitly.
```

### Hint policy

| Rule | Detail |
|------|--------|
| Max frequency | At most **once per intent type per day** per project |
| Skip hint when | question, trivial one-liner, user already used `/…` or `$…` |
| Cursor | No `/` — suggest phrase: «Start feature workflow for …» or `@kit-workflow` |
| Opt-out | `.ai/tracker.yaml` → `ux_hints: false` |

Optional throttle file (gitignore in target projects): `.ai/ux-hints.json`:

```json
{ "feature": { "last_hint": "2026-06-18", "command_used": false } }
```

Read `.ai/tracker.yaml` in the **target project** when present:

```yaml
ux_hints: true   # false disables soft command hints
```

## Anti-patterns

| Do not | Why |
|--------|-----|
| Gate on «use `/feature` only» | Breaks Cursor and casual NL |
| Skip spec because user said «just fix it» | Violates kit gates; offer minimal plan + confirm |
| Hint on every message | Noise |
| Different steps for text vs command | Commands become dead code |

## Phase 2 shortcuts (same table)

| Tool | Explicit shortcut | This skill |
|------|-------------------|------------|
| Claude Code | `/feature`, `/fix`, `/review`, `/ship` | NL → classify here |
| Codex | `$feature`, `$intent-router` | `$intent-router` or implicit match |
| Cursor | `@kit-workflow`, `@intent-router` | Step 0 in rules + this skill |
| Antigravity | `.agents/workflows/*` (Phase 2) | AGENTS.md + this skill |

Commands and workflows (Phase 2 [P2]) inject the same routing table — do not fork behaviour.
