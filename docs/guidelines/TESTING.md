# Testing guidelines

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

## Coverage requirements

Every behaviour change needs:

- **Happy path** — normal success flow.
- **Sad paths** — nil/blank input, invalid data, unauthorized access, boundary values.
- **Edge cases** — off-by-one, max length, concurrency where relevant.

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

- **Mock:** external HTTP, email/SMS, time (`freeze_time`, fake timers).
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
