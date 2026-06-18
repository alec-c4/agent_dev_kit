# Completion verification

Before a task is considered **done**, a **separate verifier agent** must run — fresh session, no writer chat history.

This gate runs **after implementation**, **before commit or PR**. It complements [REVIEW.md](REVIEW.md) (security, spec ACs, DoD); verification focuses on **executable checks** and **documentation truth**.

## When to run

Mandatory when:

- A feature, bug fix, or refactor is ready for review
- The writer agent considers the task complete
- Before `git commit` or opening a PR

Skip only for trivial changes (typo, comment) when the human agrees.

## Verifier agent rules

1. **New session** — do not continue the writer's conversation.
2. **Read inputs:**
   - `.ai/*-spec.md` (if exists)
   - `.ai/*-plan.md` (if exists)
   - `git diff` / staged diff
   - Relevant docs touched or that should have been updated (README, API docs, config reference)
3. **Run commands** — resolve from stack profile, never guess:

```bash
bash scripts/detect-stack.sh --write-profile
# profile.tooling.test, .lint, .typecheck, .security
```

4. **Report** — use the output format below. Save to `.ai/*-verification.md` (recommended).
5. **Block completion** on any FAIL in mandatory checks.

## Mandatory checks

| # | Check | How |
|---|-------|-----|
| 1 | **Tests pass** | Run `tooling.test` from stack profile on changed scope or full suite per project norm. Exit 0 required. |
| 2 | **Linter clean** | Run `tooling.lint` (and `tooling.typecheck` if defined). No new errors in changed files. |
| 3 | **Docs updated** | Every public behaviour, API, CLI flag, or config change has a matching doc update in the same task. |
| 4 | **Implementation matches docs** | Docs describe what the code actually does — no stale examples, wrong flags, or missing endpoints. |

Optional when profile defines them: `tooling.security`, `tooling.deps_audit`.

## Documentation sync

For each change in the diff, ask:

- Did we add or change a **public interface** (API route, CLI, config key, exported function)?
- Is there a **doc file** that must reflect it (README, `docs/`, OpenAPI, inline module docs)?
- Do **examples** in docs still run and match signatures?

| Change type | Expected doc action |
|-------------|---------------------|
| New endpoint / command | Documented in API or README reference |
| Config option added/removed | Config reference updated |
| Behaviour change | Changelog or migration note if project uses one |
| Internal-only refactor | No user-facing doc required |

**FAIL** if code and docs disagree, or docs are missing for a public change.

## Spec conformance

When `.ai/*-spec.md` exists, verify each acceptance criterion — see [SPECS.md](SPECS.md). Include results in the verification report.

## Output format

Save as `.ai/issue-{n}-verification.md` or `.ai/task-verification.md`:

```markdown
# Verification: [task name]

**Agent:** verifier (fresh session)
**Verdict:** PASS | FAIL
**Scope:** [branch, commit range, or PR]

## Executable checks

| Check | Command | Result | Notes |
|-------|---------|--------|-------|
| tests | `…` | PASS/FAIL | |
| lint | `…` | PASS/FAIL | |
| typecheck | `…` | PASS/SKIP | |

## Documentation

| Item | Status | Evidence |
|------|--------|----------|
| Public changes documented | PASS/FAIL | file paths |
| Docs match implementation | PASS/FAIL | mismatches listed |

## Spec conformance

(if spec exists)

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | PASS/FAIL/PARTIAL | |

## Blockers

- …

## Verifier sign-off

Task ready for human review and commit: YES / NO
```

## After verification

| Verdict | Action |
|---------|--------|
| **PASS** | Proceed to [REVIEW.md](REVIEW.md) security checklist if not already done; then human approval for commit/PR |
| **FAIL** | Return to writer agent with blocker list; re-run verification after fixes |

Do not mark a task complete or commit while verification is FAIL or skipped (unless human explicitly waives).

## Writer agent responsibility

The writer must **not** self-verify and declare done. Prompt the human or orchestrator to launch the verifier agent, or hand off with:

> Implementation complete. Run completion verification per docs/guidelines/VERIFICATION.md in a **new agent session**.
