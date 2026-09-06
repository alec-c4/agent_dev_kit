# Testing guidelines

Stack-agnostic. Framework runners, factories, and policy libraries belong in stack profiles and framework skills — not here.

## Spec-first, then TDD

For non-trivial work, an approved **spec** comes first — see [SPECS.md](SPECS.md). TDD implements the spec incrementally:

1. **Spec** — acceptance criteria (AC-1, AC-2, …) in `.ai/*-spec.md`.
2. **Red** — failing test for one AC (reference AC id in test name or comment).
3. **Green** — minimum code to pass.
4. **Refactor** — clean up while tests stay green.
5. Repeat for next AC.

If the user or project has a TDD rule (for example Cursor `tdd.mdc`), treat it as authoritative.

## Default: test-driven development

Follow Red → Green → Refactor unless the user explicitly opts out.

## What to test (critical behaviour only)

Tests exist to protect **risk and contracts**, not to mirror every line of code.

**Write tests for:**

- Spec acceptance criteria (AC IDs) and user-visible behaviour.
- **Role-based access** to the feature under development (see below) — mandatory whenever roles or permissions touch the change.
- Money, identity, data integrity, irreversible side effects.
- Boundaries with external systems (HTTP, mail, queues) — prefer contract tests + mocks at the edge.
- Regressions that already bit the project (once fixed, keep a focused example).

**Do not write tests for:**

- Library or framework wiring the dependency already covers (role-check helpers from an authz gem, ORM association macros with no app logic, feature-flag bootstrap).
- Trivial predicates and pure config (always-true toggles, constant lists, one-line ID formatters) unless a bug already escaped.
- Private helpers fully exercised by a higher-level example.
- “Coverage padding” — examples that only assert code was called or that a module loads.

Prefer **fewer, higher-level examples** (API, UI, or authorization layer the product uses) over many low-level tests that restate the implementation.

When unsure: ask whether a failure of this test would catch a **real product bug**. If not, skip it.

## Role-based access (mandatory when roles apply)

Protected behaviour must be exercised **for the roles that matter**, from several angles — not only the happy path as an allowed user.

Build a small **access matrix** for the change (table in the plan/spec or implied by ACs). For each protected action, cover the actors that can differ in outcome:

| Angle | Typical actor | Assert |
|-------|---------------|--------|
| Denied — anonymous | signed-out visitor | forbidden / unauthorized / not found per product contract |
| Denied — wrong role | signed-in user without the required role | same |
| Denied — wrong scope | member of **another** tenant/resource, or elevated role that must not leak into this resource | same |
| Allowed — intended role | role named in the AC | success |
| Allowed — elevated | platform-wide admin (if the product grants override) | success **only if** intended |

Rules:

- **Both allow and deny** for each protected action — one “admin can” example is not enough.
- Prefer the level where access is enforced for the user (HTTP/API, UI flow, or the app’s authorization layer) over unit tests that only call a library’s role-check helper.
- Scope matters: global vs resource-scoped roles are different actors; test the confusion the bug would create.
- When a feature flag gates access, include the **flag-off** (and, if relevant, actor-not-in-rollout) deny path.
- Skip roles that cannot reach the surface yet — do not invent fictional personas.

## Coverage of critical paths

For each **critical** behaviour change (usually an AC):

- **Happy path** — normal success flow for an **allowed** role.
- **Access matrix** — deny/allow for the roles and scopes above whenever the change is permission-sensitive.
- **Sad paths that matter** — invalid input the product must reject, nil/blank where the contract forbids it.
- **Edge cases** — only where the risk is real (money, concurrency, max length the product enforces).

Do **not** invent sad paths for every public method. Skip edges that cannot fail meaningfully in production.

## Structure (AAA)

1. **Arrange** — setup data and dependencies.
2. **Act** — invoke the unit under test.
3. **Assert** — verify outcome.

One logical assertion per test (multiple expects/asserts are fine when they verify the same behaviour).

## Isolation

- Tests must not depend on execution order.
- Reset state per test (transactions, truncation, in-memory doubles).
- No shared mutable state between cases.
- Design for parallel execution.

## Mocking

- **Mock:** external HTTP, email/SMS, time (clock freezes / fake timers).
- **Do not mock:** the database (use a real test DB), internal business logic.
- Prefer factories/fixtures over manual object construction.

## Naming

Test names are sentences: `returns 404 when user is not found`, not `test_user`.

## Stack tooling

Resolve test runner from the stack profile — never hardcode in guidelines:

```bash
bash scripts/detect-stack.sh --write-profile
# → skills/stacks/<id>/profile.yaml → tooling.test
```

Stack-specific testing patterns belong in `skills/stacks/<id>/` and framework skills — not in this file.

## Definition of Done

- **Universal:** `registry/dod.yaml`
- **Stack overlay:** `skills/stacks/<id>/profile.yaml` → `dod_overlay`
