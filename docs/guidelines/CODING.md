# Coding guidelines

Pragmatic standards for all stacks. Stack-specific overlays live in `registry/stacks.yaml` and framework skills (Phase 2+).

## Philosophy

- Match existing project conventions before introducing new patterns.
- Prefer the smallest correct change over abstraction.
- Do not refactor unrelated code in the same task.

## Naming

- Functions and variables: describe intent, not implementation.
- Booleans: prefix with `is_`, `has_`, `can_`, `should_`.
- Constants: `SCREAMING_SNAKE_CASE` (Ruby, Python, Go) or equivalent.

## Functions

- Single responsibility: one function, one job.
- Target 20 lines or fewer — extract helpers when longer.
- Prefer pure functions where side effects are not required.

## Code quality

- No dead code, unused imports, or commented-out blocks.
- No magic numbers — use named constants.
- No nesting deeper than three levels — early returns or extracted methods.
- Prefer explicit code over clever shortcuts.

## Comments

- Explain **why**, not **what**.
- Comment non-obvious constraints, workarounds, and business rules only.

## Security (summary)

See [REVIEW.md](REVIEW.md) for the full checklist. Minimum bar:

- No hardcoded secrets.
- Parameterized queries only.
- Validate input at system boundaries.
- Check authorization on every protected operation.

## User and tool rules

When the developer has stricter global or project rules (for example Cursor `~/.cursor/rules/`), **those win on conflict**. This file supplements them; it does not replace them.
