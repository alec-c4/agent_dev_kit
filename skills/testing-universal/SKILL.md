---
name: testing-universal
description: Stack-agnostic testing principles — TDD, AAA, isolation, coverage expectations.
---

# Universal testing

Stack-specific examples and runners live in **`skills/stacks/<id>/`** and framework pattern skills — not here.

## Principles

- Test **behaviour**, not implementation.
- **AAA:** Arrange → Act → Assert.
- One logical assertion per test.
- Tests are **isolated** — no order dependency, no shared mutable state.
- Design for **parallel** execution.
- **Never delete** a failing test to green the suite.

## TDD

Red → Green → Refactor unless the user opts out. See [docs/guidelines/TESTING.md](../../docs/guidelines/TESTING.md).

## Coverage

Every change needs:

- Happy path
- Sad paths (nil, invalid, unauthorized, boundary)
- Relevant edge cases

## Mocking

- **Mock:** external HTTP, messaging, time.
- **Do not mock:** the database (use a real test DB), core business logic.

## Commands

Resolve test runner from stack profile — do not hardcode:

```bash
bash scripts/detect-stack.sh --write-profile
# profile.tooling.test
```

## Stack-specific testing

After detection, read:

- `skills/stacks/<id>/SKILL.md` — tooling
- Pattern skills from `skills_to_load` (for example `rails-testing-rspec`, framework test guides)

Add stack-specific testing guidance only in those skills, not in guidelines or registry.
