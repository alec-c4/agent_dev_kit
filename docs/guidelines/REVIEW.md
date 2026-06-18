# Code review guidelines

Review is a **signal**, not an authoritative verdict. Re-running review on the same diff may differ — use severity to prioritize.

**Prerequisite:** [VERIFICATION.md](VERIFICATION.md) must pass in a separate agent session before review (tests, lint, docs sync). [COMPREHENSION.md](COMPREHENSION.md) sign-off must be complete for tier ≥ standard before verification runs.

## When to review

- Before every commit (mandatory when review hooks are enabled).
- Before opening or updating a PR.
- After addressing review feedback.

## Step 0: Security questions (mandatory)

Read the diff first. Answer all four — do not skip or assume:

```bash
git diff --staged    # or git diff main...HEAD for a PR
```

1. **State transitions** — Are lifecycle/state changes guarded? Can an object reach invalid states?
2. **Data isolation** — Can any user read, write, or infer another user's data?
3. **External failures** — What happens when HTTP, queue, DB, cache, or email fails or times out?
4. **Untested edge cases** — Which branches lack tests (nil, empty, unauthorized, boundaries)?

Fix real risks before proceeding.

## Spec conformance (when `.ai/*-spec.md` exists)

**Verifier agent** — use a fresh session. Read the spec and diff only; do not rely on writer chat history.

For each acceptance criterion (AC-1, AC-2, …):

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | PASS / FAIL / PARTIAL | test name, file:line, or behaviour observed |

- **FAIL** and **PARTIAL** are blockers (same severity as `major` minimum).
- If the implementation is correct but the spec was wrong, stop and request spec update + human re-approval — do not silently drift.

See [SPECS.md](SPECS.md).

## Review areas

Check all six areas. Cite `file:line` for every finding.

| Area | Focus |
|------|-------|
| Test coverage | Happy + sad paths; isolation; meaningful assertions |
| Coding guidelines | [CODING.md](CODING.md), project conventions |
| Code quality | Complexity, duplication, dead code, performance (N+1, etc.) |
| Security | Step 0 answers + [rules in CODING.md](CODING.md#security-summary) |
| Documentation | Public changes documented; docs match implementation ([VERIFICATION.md](VERIFICATION.md)) |
| Commits | [COMMITS.md](COMMITS.md) — format, scope, no attribution |

## Definition of Done

Load checklist via stack profile:

```bash
bash scripts/detect-stack.sh --write-profile
```

Uses universal `registry/dod.yaml` + `dod_overlay` from `skills/stacks/<id>/profile.yaml`.

Run from profile when available:

- `tooling.test`
- `tooling.lint`
- `tooling.security`
- `tooling.typecheck`

## Severity

| Level | Meaning |
|-------|---------|
| `critical` | Must fix before merge — security, data loss, broken behaviour |
| `major` | Should fix — bugs, missing tests for core paths |
| `minor` | Nice to fix — clarity, small refactors |
| `nit` | Style preference — non-blocking |

## Output format (fixed)

Use this structure exactly — no extra top-level sections:

```markdown
## Review summary

**Verdict:** APPROVED | CHANGES REQUESTED
**Scope:** [files or PR link]

## Security checklist

1. State transitions: [answer]
2. Data isolation: [answer]
3. External failures: [answer]
4. Untested edge cases: [answer]

## Spec conformance

(Include this section when `.ai/*-spec.md` exists for the task.)

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | PASS/FAIL/PARTIAL | … |

## Definition of Done

| Criterion | Status | Evidence |
|-----------|--------|----------|
| … | PASS/FAIL | file:line or command output |

## Findings

### critical
- [ ] file:line — problem — suggested fix

### major
…

### minor
…

### nit
…

## Quality checks

| Check | Result |
|-------|--------|
| tests | pass/fail |
| lint | pass/fail |
| security scan | pass/fail/skip |
```

## Developer approval

After presenting the review, **stop and wait**:

> Review complete. Do you approve these changes for commit?

Do not commit until the developer explicitly approves.

When review hooks are installed (Phase 3), approval creates the review-passed flag for the next commit.

## Large changes

Use a **writer / verifier** split:

1. **Writer** — implements from approved spec + plan ([SPECS.md](SPECS.md)).
2. **Verifier** — fresh context; checks spec ACs + this review document.
