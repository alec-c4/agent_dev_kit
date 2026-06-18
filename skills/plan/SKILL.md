---
name: plan
description: Write implementation plan after approved spec — no production code yet. Use when user runs /plan or asks for a plan only.
user-invokable: true
---

# Plan workflow

**Explicit invoke** — skip [intent-router](../intent-router/SKILL.md) classification.

## Intent

**Plan only** — produce `.ai/work/{work_ref}-plan.md` after an **approved** spec. No production code in this session unless human explicitly asks.

## Prerequisites

- Spec exists and is **approved** (`.ai/specs/{spec_key}-spec.md` or legacy path).
- **work_ref** and **spec_key** set ([TRACKER.md](../../docs/guidelines/TRACKER.md)).

## Steps

1. Read approved spec and analysis.
2. Run `./scripts/kit detect-stack --write-profile`; load stack skill if needed.
3. Write `.ai/work/{work_ref}-plan.md` per [WORKFLOW.md](../../docs/guidelines/WORKFLOW.md):
   - **Detail:** minimal | standard | detailed (match task size).
   - Phases, files, AC ID mapping, stack commands from profile.
4. **Present plan; wait for approval** before implementation.

## First message

Announce: **Following plan workflow** — writing plan from approved spec; no code until plan is approved.

## Do not

- Write production code before plan approval.
- Invent spec ACs — trace every step to spec IDs.
