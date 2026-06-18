# Human comprehension gate

The kit protects **code quality** (spec, tests, verification, review). This document protects **human competence** — the developer must understand and own what ships.

**Problem:** rubber-stamping spec/plan, committing green CI without reading the diff, and losing mental model of data flow and module boundaries.

**Goal:** the human stays the **control plane**. The kit amplifies work; it does not replace understanding.

See also [WORKFLOW.md](WORKFLOW.md), [VERIFICATION.md](VERIFICATION.md), [SPECS.md](SPECS.md).

## Principles

1. **Separate roles** — verifier checks execution; comprehension checks **human understanding**. Do not merge these checklists.
2. **Active recall** — answering questions in your own words beats reading an agent summary.
3. **Summary supplements, not replaces** — handoff doc points to files; the human still names what they read.
4. **Tier by risk** — typos skip the gate; auth and data model use strict tier.
5. **No fake sign-off** — agents must not fill `Human sign-off` or comprehension answers for the human.

## Comprehension tiers

Configure in `.ai/tracker.yaml` → `comprehension_gate` (default: **standard** when file absent).

| Tier | When | Handoff doc | Q&A | Manual AC | Teach-back |
|------|------|-------------|-----|-----------|------------|
| **minimal** | Typo, comment, one-line with no behaviour change | Skip | Skip | Skip | Skip |
| **standard** | Typical feature or fix (default) | Required | 3 questions | 1 per task | Skip |
| **strict** | Auth, money, data model, infra, cross-cutting | Required | 5 questions | All ACs marked `human-verify` | Required (short paragraph) |

**Align with plan Detail:** use the **same** tier as plan `Detail` when possible (minimal/minimal, standard/standard, detailed/strict).

Human may **lower** tier with explicit confirm: «comprehension minimal for this task». Agent may **suggest raising** tier when spec touches security or persistence — one confirm, not a lecture.

## Artifact: handoff document

After implementation, **before verification**, write:

`.ai/work/{work_ref}-handoff.md` (or `task-handoff.md` without tracker)

Template:

```markdown
# Handoff: [task name]

**Work ref:** GH-58
**Comprehension tier:** standard
**Spec:** specs/export-csv-spec.md v1.1

## What changed

- … (max 5 bullets)

## Data flow

How data enters, transforms, and exits (3 sentences or a small diagram).

## Key files

| Path | Role |
|------|------|
| `app/…` | … |

## Decisions

- Chose X over Y because …

## If it breaks

First places to inspect (logs, files, config keys).

## Manual verification (from spec)

| AC | Scenario | Human result |
|----|----------|--------------|
| AC-2 | … | PASS / FAIL — notes |

## Comprehension Q&A

Agent generates questions **after** handoff draft; human answers **before** sign-off.
Agents must not answer for the human.

### Q1
**Question:** …
**Human answer:** *(human fills)*

### Q2
…

## Human sign-off

Required for tier **standard** and **strict**. Verifier treats missing sign-off as FAIL.

- **Files I read:** (paths — at least one core file from Key files)
- **I can explain:** (one sentence in your own words)
- **Teach-back:** *(strict tier only — 2–3 sentences as if explaining to a colleague)*
- **Signed:** YYYY-MM-DD
```

Example: [docs/examples/work/GH-58-handoff.example.md](../examples/work/GH-58-handoff.example.md).

## Comprehension Q&A rules

1. Generate **3** questions (standard) or **5** (strict) from spec + handoff + diff summary.
2. Questions test **behaviour and structure**, not line numbers — e.g. «Where is UTF-8 enforced?» not «What is on line 42?»
3. Wait for human answers. If answers conflict with spec or code, discuss — do not commit until resolved or spec is updated.
4. **Do not** paste answers from the codebase into the Q&A block before the human tries.

## Manual verification (acceptance criteria)

In spec, mark scenarios the human must run manually:

```markdown
- [ ] **AC-2:** … *(human-verify)*
```

| Tier | Rule |
|------|------|
| standard | At least **one** `human-verify` AC per task (add to spec if none) |
| strict | **Every** AC tagged `human-verify` must be run and recorded in handoff |
| minimal | Skip |

Manual verify means **human executes** (browser, curl, console) — not the agent declaring PASS.

## Workflow placement

```
Implement → Comprehension (handoff + Q&A + manual AC + sign-off) → Verification → Review → Commit
```

Comprehension runs **after** code is ready and **before** the verifier agent. The verifier checks that handoff exists and sign-off is complete for the active tier — see [VERIFICATION.md](VERIFICATION.md).

## Anti-patterns

| Do not | Why |
|--------|-----|
| Skip comprehension on «just fix it» without lowering tier + confirm | Bypasses ownership |
| Let the agent write Human sign-off | Fake gate |
| Replace reading the diff with handoff only | Summary is a map, not the territory |
| Generate Q&A answers from code before human tries | No active recall |
| Run comprehension after commit | Too late |

## Optional: project map (strict / periodic)

For **strict** tier or every Nth task, update `.ai/project-map.md` — modules, data stores, entry points. Human **edits** the map; agent proposes diff.

Phase 2 adds skill `comprehension-check` and `validate-handoff.sh`. Phase 3 may add an opt-in hook blocking commit without sign-off.

## Automation

| Component | Status | Role |
|-----------|--------|------|
| `skills/comprehension-check/SKILL.md` | shipped | Generate Q&A; validate human answers against spec |
| `scripts/validate-handoff.sh` | shipped | Structural handoff checks (`./scripts/kit validate-handoff`) |
| `.ai/tracker.yaml` | shipped | `comprehension_gate: minimal\|standard\|strict` |
| Hook (opt-in) | planned | Require `Signed:` in handoff before `git commit` |
