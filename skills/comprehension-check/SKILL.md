---
name: comprehension-check
description: Generate comprehension Q&A from spec and handoff; validate human answers before verification. Use after implement, before verifier session.
user-invokable: true
---

# Comprehension check

Human **comprehension gate** — separate from verification and review. See [COMPREHENSION.md](../../docs/guidelines/COMPREHENSION.md).

## When to use

- After implementation, **before** verification agent session.
- When tier is **standard** or **strict** (from `.ai/tracker.yaml` or handoff header).
- Invoked by [feature](../feature/SKILL.md), [fix](../fix/SKILL.md), or [resolve-task](../resolve-task/SKILL.md) step 6.

Skip when tier is **minimal** (human may lower tier with explicit confirm).

## Inputs

| Input | Path |
|-------|------|
| Spec | `.ai/specs/{spec_key}-spec.md` |
| Handoff draft | `.ai/work/{work_ref}-handoff.md` |
| Diff summary | `git diff main...HEAD` or staged diff |
| Tier | `.ai/tracker.yaml` → `comprehension_gate` (default **standard**) |

Example handoff: [GH-58-handoff.example.md](../../docs/examples/work/GH-58-handoff.example.md).

## Protocol

### 1. Resolve tier

Read `comprehension_gate` from `.ai/tracker.yaml` if present. Align with plan **Detail** when handoff lists a tier.

| Tier | Handoff | Q&A count | Manual AC | Teach-back |
|------|---------|-----------|-----------|------------|
| minimal | Skip | 0 | Skip | Skip |
| standard | Required | 3 | ≥1 `human-verify` AC | Skip |
| strict | Required | 5 | All `human-verify` ACs | Required |

Suggest **raising** tier when spec touches auth, money, persistence, or infra — one confirm only.

### 2. Draft or update handoff

Ensure `.ai/work/{work_ref}-handoff.md` has: What changed, Data flow, Key files, Decisions, If it breaks, Manual verification table.

Do **not** write **Human sign-off** or Q&A **answers** for the human.

### 3. Generate Q&A

Write questions into the handoff **Comprehension Q&A** section:

- **Standard:** 3 questions  
- **Strict:** 5 questions  

Rules:

- Test **behaviour and structure** — not line numbers.
- Derive from spec ACs, handoff data flow, and diff summary.
- Leave `**Human answer:**` empty for the human to fill.

Example question types:

- Where is validation or encoding enforced?
- What happens when an external dependency fails?
- Why was approach A chosen over B (from Decisions)?

### 4. Wait for human answers

Stop until the human fills each **Human answer** block. If an answer conflicts with spec or code:

1. Discuss — do not commit.
2. Update spec (with approval) or fix code — then regenerate Q&A if behaviour changed.

### 5. Validate answers (agent)

After human answers exist, check each answer against spec + code:

| Result | Action |
|--------|--------|
| Consistent | Proceed to sign-off checklist |
| Partial / vague | Ask **one** follow-up — do not lecture |
| Wrong | Block until resolved |

Run structural check:

```bash
./scripts/kit validate-handoff {work_ref}
```

Fix missing sections before verification.

### 6. Human sign-off

Human completes (never agent):

- **Files I read:** at least one path from Key files  
- **I can explain:** one sentence in their own words  
- **Teach-back:** strict tier only — 2–3 sentences  
- **Signed:** YYYY-MM-DD  

## Output

Updated `.ai/work/{work_ref}-handoff.md` with Q&A and completed human sign-off. Verifier session reads this file — see [VERIFICATION.md](../../docs/guidelines/VERIFICATION.md).

## Do not

- Fill Human sign-off or Q&A answers for the human.
- Skip comprehension on «just fix it» without lowering tier + confirm.
- Run comprehension after commit.
- Merge comprehension checklist into verification — keep roles separate.
