---
name: testing-universal
description: Stack-agnostic testing principles — TDD, AAA, role access matrix, critical-path coverage (not tests-for-coverage).
---

# Universal testing

Stack-specific examples and runners live in **`skills/stacks/<id>/`** and framework pattern skills — not here.

## Principles

- Test **behaviour**, not implementation.
- Test **critical** behaviour only — AC contracts, **role-based access**, money/identity/integrity, external boundaries, known regressions.
- When a change is permission-sensitive: exercise access **for the relevant roles from several angles** (anonymous, wrong role, wrong scope/resource, allowed role, elevated override if any). Allow **and** deny — not only the happy path.
- **Do not** write tests for library/framework wiring, trivial config/predicates, or coverage padding. Prefer higher-level examples over low-level mirrors of authz helpers.
- **AAA:** Arrange → Act → Assert.
- One logical assertion per test.
- Tests are **isolated** — no order dependency, no shared mutable state.
- Design for **parallel** execution.
- **Never delete** a failing test to green the suite (delete only when the behaviour is intentionally removed or the example was never valuable).

## TDD

Red → Green → Refactor unless the user opts out. See [docs/guidelines/TESTING.md](../../docs/guidelines/TESTING.md).

## Coverage

For each **critical** change (usually a spec AC):

- Happy path for an **allowed** role
- **Access matrix** when roles/permissions apply (deny + allow; global vs resource scope)
- Other sad paths **that matter** (invalid input the product must reject)
- Edge cases **only when risk is real**

Skip inventing edges for every public method. If a failing test would not catch a real product bug, do not add it. Full matrix guidance: [TESTING.md](../../docs/guidelines/TESTING.md) § Role-based access.

## Mocking

- **Mock:** external HTTP, messaging, time.
- **Do not mock:** the database (use a real test DB), core business logic.

## Commands

Resolve test runner from the stack profile — do not hardcode:

```bash
bash scripts/detect-stack.sh --write-profile
# profile.tooling.test
```

## Stack-specific testing

After detection, read:

- `skills/stacks/<id>/SKILL.md` — tooling
- Pattern skills from `skills_to_load` (for example framework test guides)

Add stack-specific testing guidance only in those skills, not in guidelines or registry.
