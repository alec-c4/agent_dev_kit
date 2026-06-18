# Specification-first development

Write a **behavior spec** before implementation. The spec is the durable contract between humans, the implementing agent, and a **verifying agent** in a separate session.

Works together with [TDD](TESTING.md): the spec defines *what*; tests prove it; TDD drives *how* incrementally.

## Why specs

- **Context survives sessions** — the spec lives in `.ai/`, not in chat history.
- **Clear acceptance criteria** — no ambiguity about "done".
- **Independent verification** — another agent reads spec + diff without writer bias.
- **Better tests** — Red-phase tests trace back to spec scenarios.

## Spec vs plan vs tests

| Artifact | Question it answers | File |
|----------|---------------------|------|
| **Spec** | What behaviour is required? | `.ai/*-spec.md` |
| **Plan** | How will we build it? (files, gems, generators, steps) | `.ai/*-plan.md` |
| **Tests** | Does the code satisfy the spec? | test suite |

Order: **spec → plan (human approval) → TDD → verification**.

## Implementation details: spec or plan?

**Default: implementation details go in the plan, not the spec.**

| Put in **spec** | Put in **plan** |
|-----------------|-----------------|
| Observable behaviour (ACs) | Concrete files and paths |
| User-visible rules | `bundle add`, `npm install`, generators |
| Security / compliance **requirements** | Refactors of existing modules |
| Forbidden approaches (when non-negotiable) | Step order, estimates |
| Integration constraints ("must use existing AuthService") | Stack-specific commands from profile |

### Why not dump everything into the spec?

- **Verifier** checks behaviour and docs — not "did you run `rails g`".
- **Specs stay stable** when the team picks a different library during planning.
- **Stack-agnostic** specs can be reviewed by humans who care about *what*, not *how*.
- **Less rework** — changing approach bumps the plan, not a versioned behaviour contract.

### When spec *should* mention implementation

Add an optional **Constraints** section only for **non-negotiable** technical decisions:

```markdown
## Constraints

- Must use existing `AuthorizationPolicy` — no ad-hoc checks in controller.
- Must not add gems without human approval.
- Must store files via configured ActiveStorage (no direct S3 calls).
```

These are **requirements**, not recipes. If the constraint affects observable behaviour, also reflect it in an AC.

Do **not** put in spec:

- "Run `rails g model User`"
- Full code snippets
- File trees (belongs in plan)

### Does a separate plan complicate things?

| Situation | Recommendation |
|-----------|----------------|
| Trivial task (one file, obvious fix) | Plan **Detail: minimal** — see [WORKFLOW.md](WORKFLOW.md) |
| Medium / large task | **standard** or **detailed** plan |
| Human already knows exact steps | Steps in **plan**; spec stays behaviour-only |

**Net effect:** two documents add one approval step but **reduce** drift, wrong libraries, and verifier confusion. Implementation recipes in spec **look** faster but **increase** rework when the approach changes.

See [plan example](../examples/specs/issue-58-plan.example.md) vs [spec examples](../examples/specs/README.md).

Skip the written spec only for trivial changes (typo, one-line with no behaviour impact) or when the human explicitly opts out.

## New task vs fix vs update

Classify every task before writing or editing a spec:

| Task type | Spec action | Version |
|-----------|-------------|---------|
| **New** | Create new spec file | **1.0** |
| **Fix** (bug on existing feature) | Update existing spec for that feature/issue | Bump **patch** (1.0 → 1.1) |
| **Update** (extend or change existing feature) | Actualize existing spec | Bump **minor** (1.0 → 1.1) or **major** (1.x → 2.0) if scope shifts |

**Rule:** one feature area → one spec lineage (one issue or epic id). Fixes and updates **edit that spec**, they do not silently fork a second file.

### How to find the spec to update

1. Same GitHub issue / ticket → `.ai/issue-{n}-spec.md`
2. Follow-up task without issue → search `.ai/` for feature name or `related_issue`
3. No spec exists but code clearly implements a prior feature → create spec at current behaviour first (retroactive **1.0**), then bump for the fix/update

### Version numbering

Use semantic-style **document version** in the spec header:

| Bump | When | Example |
|------|------|---------|
| **1.0** | First spec for this task/feature | New export feature |
| **1.1** | Clarification, bug fix, small AC add/change | Fix CSV encoding; add AC for empty file |
| **2.0** | Scope change, removed ACs, breaking behaviour change | Export format changes from CSV to XLSX only |

Patch and minor both use 1.1, 1.2, … — pick the next number. Reserve **2.0+** for breaking or major scope changes.

### On every version bump

1. Set `status: draft` until re-approved
2. Add a **Changelog** entry (what changed and why)
3. Archive the previous approved version → `.ai/archive/issue-{n}-spec.v{old}.md`
4. Update **Acceptance criteria** — mark added/changed/removed ACs
5. **Human re-approval** required before plan or code (same as new spec)

Do not implement against a draft spec version without approval.

## When to write or update a spec

Required for:

- New features (**new**, v1.0)
- Bug fixes that change or clarify behaviour (**fix**, bump version)
- Feature updates and extensions (**update**, bump version)
- Refactors that change observable behaviour

Optional for:

- Pure internal refactors with unchanged behaviour (test baseline is enough)
- Documentation-only changes (unless docs are the deliverable)

## Spec template

Save as `.ai/issue-{n}-spec.md` (always the **current** version):

```markdown
# Spec: [feature or fix name]

**Document version:** 1.0
**Status:** draft | approved
**Task type:** new | fix | update
**Issue:** #42 (or link)
**Supersedes:** — (or `1.0` — see archive)

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2026-06-10 | — | Initial spec |

## Goal
One paragraph — user-visible outcome.

## Scope
- In scope: …
- Out of scope: …

## Acceptance criteria

Stable IDs persist across versions where behaviour unchanged. New ACs get next id.

- [ ] **AC-1:** Given …, when …, then …
- [ ] **AC-2:** Given …, when …, then … (sad path)
- [ ] **AC-3:** … *(added in v1.1)*

## Edge cases
- …

## Non-goals
- …

## Constraints
*(optional — non-negotiable technical rules only; not step-by-step how-to)*

- …

## Open questions
- … (resolve before implementation)
```

For **fix/update**, the Changelog row is mandatory. Annotate changed ACs with `*(added v1.1)*`, `*(modified v1.1)*`, `*(removed v2.0)*`.

**Present the spec to the human. Wait for approval before writing the plan or code.**

**Examples:** [docs/examples/specs/](../examples/specs/README.md) — new task (v1.0), fix (v1.1), archive, and linked plan.

## Link spec to plan and tests

In `.ai/*-plan.md`, reference spec **version** and AC IDs:

```markdown
## Spec
issue-42-spec.md **v1.1** (approved)

## Phase 1 — API endpoint
- [ ] Add controller (covers AC-1, AC-2)
- [ ] Tests: AC-1 happy path, AC-2 unauthorized
```

In TDD Red phase, name tests after acceptance criteria: `AC-1: returns 201 when params valid`.

## Multi-agent verification

Use a **writer / verifier** split for non-trivial work:

| Role | Reads | Does |
|------|-------|------|
| **Writer** | Spec + plan | Implements with TDD |
| **Verifier** | Spec + diff + docs (fresh context) | Runs [VERIFICATION.md](VERIFICATION.md): tests, lint, docs sync, spec ACs |

See [VERIFICATION.md](VERIFICATION.md) for the completion gate. [REVIEW.md](REVIEW.md) covers security and DoD.

## Spec updates during implementation

If implementation reveals the spec was wrong:

1. Stop.
2. Bump document version (usually patch).
3. Update Changelog and ACs; archive previous version.
4. Re-approve with the human before continuing.

Do not silently drift from the approved spec version.
