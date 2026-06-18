# Development workflow

Structured flow from task to merge. Works with any AI assistant — read [AGENTS.md](../../AGENTS.md) first.

## Principles

1. **Detect stack first** — run detect-stack, load `skills/stacks/<id>/`; never assume framework or hardcode commands.
2. **Spec before code** — write acceptance criteria; get human approval. See [SPECS.md](SPECS.md).
3. **Plan before code** — implementation plan after approved spec (non-trivial work).
4. **TDD by default** — tests trace to spec acceptance criteria. See [TESTING.md](TESTING.md).
5. **Review before commit** — completion verification by a **separate agent** first. See [VERIFICATION.md](VERIFICATION.md), then [REVIEW.md](REVIEW.md).
6. **Guidelines compound** — when AI repeats a mistake, update the relevant guideline.

## Intent classification

Classify every request before acting:

| Intent | Spec | Workflow |
|--------|------|----------|
| Feature (new) | Create v1.0 | Spec → Plan → TDD → Verification → Review → PR |
| Feature (update) | Bump version, actualize | Same |
| Bug (fix) | Bump version, actualize ACs | Analyze → Spec update → Fix → Verification → PR |
| Refactor | Only if behaviour changes | Test baseline → … |
| Audit | — | Scan → Report → Fix plan |
| Question | — | Read code, explain — no commits |

## Planning artifacts (`.ai/`)

Store session planning files in the **target project** (not in this kit repo):

```
.ai/
  issue-{n}-analysis.md   # exploration + problem analysis
  issue-{n}-spec.md       # current spec (always latest version)
  archive/                # superseded spec versions
    issue-{n}-spec.v1.0.md
  issue-{n}-plan.md       # implementation plan (references spec AC IDs)
  issue-{n}-verification.md # verifier agent report (tests, lint, docs)
  pr-summary.md           # structured PR body draft
```

Add `.ai/` to the target project's `.gitignore` unless the team commits plans intentionally.

See [.ai/README.md](../../.ai/README.md) for artifact naming. Worked examples: [docs/examples/specs/](../examples/specs/README.md).

## Standard feature flow

### 1. Analyze

- Read the issue or user request.
- Detect stack (`registry/stacks.yaml`, `scripts/detect-stack.sh`).
- Explore affected code.
- Write `.ai/issue-{n}-analysis.md` (or `.ai/task-analysis.md` without issue number).

### 2. Spec

- **New task:** create `.ai/issue-{n}-spec.md` at version **1.0** — [SPECS.md](SPECS.md).
- **Fix or update:** open existing spec, bump version, Changelog, archive old file, actualize ACs.
- **Present spec to the human. Wait for approval before plan or code.**

### 3. Plan

- Produce `.ai/issue-{n}-plan.md` with phases, files, and links to spec AC IDs.
- Set **Detail** to match task size — see table below (default: **standard**).
- **Present plan to the human. Wait for approval before production code.**

#### Plan detail levels

Match depth to task size. Shallow plans save tokens; deep plans save rework on complex tasks.

| Detail | When | Spec | Plan contents | Who reads plan |
|--------|------|------|---------------|----------------|
| **minimal** | One file, obvious fix, typo | Optional | Summary + 1–5 steps, no phases | Writer only |
| **standard** | Typical feature or fix | Required | Phases, files, AC mapping, stack | Writer; verifier skips plan |
| **detailed** | Multi-module, new patterns, multi-agent | Required | Standard + commands, order, risks, rollback | Writer; verifier still uses **spec** only |

**Token rule:** do not write **detailed** for **minimal** tasks. Do not write **minimal** when the task touches auth, money, or cross-cutting modules — use **standard** or **detailed**.

Example: [minimal plan](../examples/specs/issue-99-plan.minimal.example.md) · [standard plan](../examples/specs/issue-42-plan.example.md)

Plan template:

```markdown
# Plan: [name]

**Detail:** standard
**Spec:** issue-{n}-spec.md **v1.1** (approved)

## Summary
What and why.

## Stack
Detected: [from stack profile]

## Implementation steps

*(omit or shorten for minimal)*

- [ ] …

## Phases
*(omit for minimal)*

### Phase 1 — [name] (S/M/L)
- [ ] …

## Success criteria
- [ ] All spec AC IDs covered
- [ ] Tests + lint per VERIFICATION.md
```

### 4. Branch

```bash
git checkout -b feature/short-description
```

Follow [GIT.md](GIT.md).

### 5. Implement

- TDD per [TESTING.md](TESTING.md) — tests map to spec acceptance criteria.
- Match [CODING.md](CODING.md) and project conventions.
- Small commits per [COMMITS.md](COMMITS.md).

### 6. Completion verification

**Mandatory.** Launch a **verifier agent in a new session** — see [VERIFICATION.md](VERIFICATION.md):

- Tests pass (stack profile commands)
- Linter / typecheck clean
- Documentation updated for public changes
- Implementation matches documentation
- Spec ACs satisfied (if spec exists)

Save report to `.ai/issue-{n}-verification.md`. **Do not commit while verdict is FAIL.**

### 7. Review

Follow [REVIEW.md](REVIEW.md) for security checklist and DoD (verifier may combine with step 6 in one fresh session).

### 8. Pull request

- Draft summary in `.ai/pr-summary.md`.
- Open PR with test plan checklist.

## Escalation (unknown tasks)

When official docs and codebase search do not resolve a question:

1. State what you tried and what you found.
2. Do not invent APIs or framework behaviour.
3. Ask the human how to proceed.

See the developer's `unknown-tasks` rule when present.

## Request validation

Before destructive, irreversible, or broad-scope actions, warn and confirm. See the developer's `request-validation` rule when present.

## Tool-specific shortcuts (optional)

Some tools expose workflow shortcuts that encode this document:

| Tool | Mechanism | Phase |
|------|-----------|-------|
| Claude Code | Slash commands (`/feature`, `/fix`, …) | 2+ |
| Cursor | Skills, rules, agent prompts | 1+ |

Prefer guidelines directly when no shortcut exists.

## Definition of Done

- Universal: `registry/dod.yaml`
- Stack overlay: `skills/stacks/<id>/profile.yaml`
- Combined list: `.claude/stack.profile.json` → `dod_checklist`
