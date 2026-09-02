# Completion verification

Before a task is considered **done**, a **separate verifier agent** must run — fresh session, no writer chat history.

This gate runs **after** [comprehension sign-off](COMPREHENSION.md) and **after implementation**, **before commit or PR**. It complements [REVIEW.md](REVIEW.md) (security, spec ACs, DoD); verification focuses on **executable checks** and **documentation truth**.

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
   - `.ai/work/{work_ref}-findings.md` (open/regressed **block** rows)
   - `.ai/*-handoff.md` (if tier ≥ standard — see [COMPREHENSION.md](COMPREHENSION.md))
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
| 5 | **Comprehension gate** | For tier **standard** or **strict**: handoff exists, Q&A answered, manual-verify ACs recorded, **Human sign-off** with date. FAIL if missing or agent-filled. Skip for **minimal** tier. |

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

When `.ai/*-spec.md` exists, verify each acceptance criterion — see [SPECS.md](SPECS.md). Include results in the verification report. Agent-verified ACs only; `human-verify` ACs are confirmed via handoff manual verification table.

## Durable findings

If a check above surfaces a fact the spec didn't already state (a constraint, gotcha, or architectural rule the writer had to discover), don't let it live only in this report:

- Behaviour-relevant → add it to the spec's `## Constraints` (bump version per [SPECS.md](SPECS.md)).
- Cross-cutting / stack-level → add it to the relevant `docs/guidelines/` file or stack skill.

Note in the report whether any durable finding was promoted, and where.

## Findings ledger

On every FAIL, append a row with `./scripts/kit findings append --work-ref …` (do not leave the FAIL only in this report).

Run the gate — it decides the first two bullets for you:

```bash
./scripts/kit findings gate --work-ref {work_ref} --remediation .ai/work/{work_ref}-plan.md
```

Verification **FAIL** when:

- `./scripts/kit findings gate` exits non-zero — a `block` finding is `open`/`regressed` and not `wontfix`, or the remediations table misses one of its `F-*`
- `./scripts/kit check-patterns --work-ref {work_ref}` exits non-zero (unless `.ai/kit.yaml` has `pattern_checks: false`)
- This verification ran in the **same** agent session as the implementation — no file sensor can see this, so assert it yourself: `./scripts/kit findings append --work-ref {work_ref} --fingerprint skipped-fresh-verifier --severity block --summary "verified in the writer session" --evidence "same session as implement"` and FAIL
- A previously `closed` fingerprint hits again — status becomes `regressed`

`./scripts/kit check-patterns --list-sensors` lists the fingerprints no token scan can raise, which the verifier is responsible for asserting.

## Comprehension conformance

When `.ai/*-handoff.md` exists, verify:

| Check | PASS when |
|-------|-----------|
| Handoff present | File exists for work_ref |
| Q&A complete | Each question has **Human answer** filled by human |
| Manual verify | At least one `human-verify` AC recorded for standard tier |
| Sign-off | `Signed:` date present; **Files I read** lists ≥1 path |

**FAIL** if sign-off is missing for standard/strict tier, or if answers clearly were pasted by the agent without human attempt.

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

## Comprehension

| Check | Status | Evidence |
|-------|--------|----------|
| Handoff + sign-off | PASS/FAIL/SKIP | path to handoff |
| Manual-verify ACs | PASS/FAIL/SKIP | handoff table |

## Blockers

- …

## Durable findings promoted

- Promoted to spec/guideline: YES / NO — [where, if YES]

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
