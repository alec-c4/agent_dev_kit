---
name: rails-testing-rspec
description: RSpec patterns for Rails — request specs, factories, system tests. Load when spec/ directory exists per stacks/rails profile.
user-invocable: false
metadata:
  verify:
    gem: ["rspec-rails", "factory_bot_rails"]
---

# Rails RSpec patterns

Load when `spec/` exists ([stacks/rails](../stacks/rails/profile.yaml) `if_spec_dir`).

## Commands

From stack profile: `bundle exec rspec`, optionally `--format documentation`.

## Conventions

- **Request specs** for HTTP/API; **system specs** for critical UI flows.
- **Policy specs** (Pundit / Action Policy) for permission matrices; still add at least one request example per protected surface so routing/controllers cannot bypass the policy.
- **Factories** (FactoryBot) over fixtures for mutable data; traits for roles (`:admin`, org membership) and variants.
- **Let/let!** for lazy vs eager setup; avoid shared mutable state across examples.
- Map examples to spec **AC IDs** from `.ai/specs/*-spec.md`.

## Role access matrix

For each protected action, cover actors that change the outcome: anonymous, signed-in without role, wrong org/resource, intended role, global admin override (only if product allows). Assert allow **and** deny. Prefer request specs (`get`/`post` as each actor) over unit tests of RoleFu `has_role?`. See [TESTING.md](../../docs/guidelines/TESTING.md) § Role-based access.

## Do not

- Test Rails internals; test behaviour and contracts.
- Test gem wiring RoleFu/Flipper/Devise already covers, or trivial wrappers (`FlipperUi.enabled?`, `flipper_id` format) — cover **role access and product ACs** at request/system/policy level instead.
- Add model examples that only prove a library method works (`grant` / `has_role?`) unless the app adds custom logic on top.
- Skip VCR/WebMock boundaries for external HTTP when project uses them.
- Pad coverage with examples that would not catch a real product bug.
- Ship a protected endpoint with only an “allowed role succeeds” example and no deny cases.
