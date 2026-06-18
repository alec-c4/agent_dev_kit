---
name: review
description: Pre-commit and PR review checklist — security, DoD, diff quality. Use when user runs /review or asks to review before commit.
user-invokable: true
---

# Review workflow

**Explicit invoke** — skip [intent-router](../intent-router/SKILL.md) classification.

## Intent

**Review** — run [REVIEW.md](../../docs/guidelines/REVIEW.md) on the current diff or PR **before commit or merge**.

## Prerequisites

- [VERIFICATION.md](../../docs/guidelines/VERIFICATION.md) should pass in a **separate agent session** before review (tests, lint, docs sync).
- Comprehension sign-off complete when tier ≥ standard ([COMPREHENSION.md](../../docs/guidelines/COMPREHENSION.md)).

## Steps

1. Read the diff (staged + unstaged or PR files).
2. Run **Step 0 security questions** from REVIEW.md (mandatory).
3. Check six areas: security, correctness, tests, docs, DoD (`registry/dod.yaml` + stack overlay), scope.
4. Output findings: blockers vs suggestions.
5. Do **not** commit unless human confirms after blockers are resolved.
6. On explicit human approval, when review gate is installed: `bash hooks/mark-review-passed.sh` (or `--target=claude|cursor|agents`).

## First message

Announce: **Following review workflow** per REVIEW.md (verification should already be green).

## Do not

- Approve merge of security blockers without human ack.
- Skip verification prerequisite for non-trivial work.
