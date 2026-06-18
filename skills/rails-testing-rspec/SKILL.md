---
name: rails-testing-rspec
description: RSpec patterns for Rails — request specs, factories, system tests. Load when spec/ directory exists per stacks/rails profile.
user-invokable: false
---

# Rails RSpec patterns

Load when `spec/` exists ([stacks/rails](../stacks/rails/profile.yaml) `if_spec_dir`).

## Commands

From stack profile: `bundle exec rspec`, optionally `--format documentation`.

## Conventions

- **Request specs** for HTTP/API; **system specs** for critical UI flows.
- **Factories** (FactoryBot) over fixtures for mutable data; traits for variants.
- **Let/let!** for lazy vs eager setup; avoid shared mutable state across examples.
- Map examples to spec **AC IDs** from `.ai/specs/*-spec.md`.

## Do not

- Test Rails internals; test behaviour and contracts.
- Skip VCR/WebMock boundaries for external HTTP when project uses them.
