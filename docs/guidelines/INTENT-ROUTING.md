# Intent routing and command UX

Users often describe tasks in **plain text**. Slash commands (`/feature`, `/fix`, `/ship`) are **optional shortcuts** — not a requirement. Both paths must run the **same workflow** from [WORKFLOW.md](WORKFLOW.md).

See also [TRACKER.md](TRACKER.md) for work item intake.

## Design principle: one pipeline, two entry points

| Entry | Who chooses | Reliability | Best for |
|-------|-------------|-------------|----------|
| **Natural language** | Agent classifies intent | Probabilistic | Exploration, mixed chat, Cursor (no native `/`) |
| **Slash command / explicit phrase** | User | Deterministic | Repeat workflows, high-stakes actions, teaching the team |

**Rule:** never block plain text. Never reply with «use `/feature` only». Classify → confirm if unclear → run the same steps as a command would.

Analogues: [flow-next](https://github.com/gmickel/flow-next) accepts natural language for the same flows as `/flow-next:plan` and `/flow-next:work`. Claude Code 2026 unifies skills and commands — slash bypasses classification; description-based skills match intent from chat.

## Step 0 — classify before acting

On every non-trivial user message, before edits or commits:

1. **Classify intent** — feature (new/update), bug, refactor, audit, question, or meta (help/commands).
2. **Estimate confidence** — high | medium | low (see below).
3. **Pick workflow** from [WORKFLOW.md](WORKFLOW.md) intent table.
4. **Act or clarify** — do not skip spec/plan gates because the user wrote casually.

### Confidence bands

| Confidence | Signals | Agent behaviour |
|------------|---------|-----------------|
| **High** | Clear verb + scope: «add CSV export», «fix GH-58 encoding bug», `/fix GH-58` | Announce workflow in one line; proceed to Analyze or Spec |
| **Medium** | Ambiguous scope: «fix export», «improve auth» | One short confirm: intent + spec_key guess + next step |
| **Low** | Could be question, code, or task: «export broken», «what about CSV?» | Ask **one** disambiguation question (2–4 options) |
| **Question** | «how does X work?», «explain» | Answer only — **no** workflow nudge |

### Disambiguation example (low confidence)

> User: «export is broken»

```markdown
This could mean:
1. **Bug fix** — follow fix workflow (spec bump → plan → TDD)
2. **Investigation** — analyze only, no code yet
3. **Question** — explain current export behaviour

Which do you want?
```

Use the user's `request-validation` rule when present — one question, not a questionnaire.

## Same pipeline for text and commands

| Intent | Plain text example | Command (Phase 2, Claude Code) | First artifact |
|--------|------------------|--------------------------------|----------------|
| Feature (new) | «Add CSV export to index» | `/feature` or `/resolve-task` | `work/{ref}-analysis.md` → spec v1.0 |
| Bug fix | «Fix GH-58 UTF-8 export» | `/fix` | analysis → spec bump |
| Plan only | «Write plan for export-csv» | `/plan` | `work/{ref}-plan.md` |
| Review | «Review my diff before commit» | `/review` | REVIEW checklist output |
| Ship / PR | «Prepare PR for this branch» | `/ship` | `.ai/pr-summary.md` |
| Question | «How does export work?» | — (no command) | answer in chat |

`/deploy`, `/ship`, and anything with **external side effects** require explicit user intent — command or confirmed natural language. Do not infer deploy from vague «push it live».

## Command hints (soft discoverability)

**Problem:** text-only users may not learn that `/feature` exists.  
**Solution:** optional **one-line hint** — never blocking.

After starting a workflow from plain text (high or medium confidence):

```markdown
Following **feature workflow** (spec → plan → TDD → verification).
Tip (Claude Code): `/feature` runs the same pipeline explicitly.
```

### Hint policy (avoid annoyance)

| Rule | Detail |
|------|--------|
| Max frequency | At most **once per intent type per day** per project (or skip after user uses command once) |
| Never hint on | questions, trivial one-liners, when user already used `/…` |
| Cursor | No `/` — suggest: «Say **start feature workflow**» or enable kit-workflow rule |
| Opt-out | `.ai/tracker.yaml` → `ux_hints: false` |

Track hints optionally in `.ai/ux-hints.json` (Phase 2, gitignored):

```json
{ "feature": { "last_hint": "2026-06-18", "command_used": false } }
```

## Tool-specific entry points

| Tool | Explicit shortcut | Plain text |
|------|-------------------|------------|
| **Claude Code** | `/feature`, `/fix`, `/review`, `/ship`, `/resolve-task` | Classify → same workflow |
| **Cursor** | No native slash; `@` rules, skills, or phrases | kit-workflow.mdc + AGENTS.md Step 0 |
| **Any** | «Start feature workflow for …» | Treated as high-confidence intent |

Phase 2: `commands/*.md` (Claude Code) and skill `intent-router` (all tools) share one routing table.

## What not to do

| Anti-pattern | Why |
|--------------|-----|
| «Please use `/feature`» as gate | Friction; breaks Cursor and casual use |
| Skip spec because user said «just fix it» | Violates kit gates; offer **minimal** plan + confirm |
| Hint on every message | Noise; users ignore kit |
| Auto-deploy from «ship it» without confirm | request-validation / high-stakes rule |
| Different behaviour for text vs command | Drift; commands become dead code |

## High-stakes actions (always explicit)

Regardless of entry point, **confirm** before:

- deploy / release / merge to production
- force-push, destructive git, dependency major bumps
- skipping verification or review when DoD requires them

Slash command or typed phrase + human «yes» — both acceptable.

## Phase 2 implementation

| Component | Role |
|-----------|------|
| `skills/intent-router/SKILL.md` | Classification table, confidence rules, hint policy |
| `commands/feature.md`, `fix.md`, … | Inject same prompts as router; bypass classify |
| `commands/resolve-task.md` | Full pipeline from work_ref or pasted ticket |
| `.ai/tracker.yaml` | `ux_hints: true/false` |
| `kit-workflow.mdc` | Link INTENT-ROUTING.md Step 0 |

## Quick reference for agents

```
User message
    ↓
Question? → answer, stop
    ↓
Slash command? → map to workflow, skip classify
    ↓
Classify intent + confidence
    ↓
Low? → one clarifying question
Medium? → one-line confirm
High? → announce workflow + optional hint
    ↓
WORKFLOW.md (spec → plan → …)
```
