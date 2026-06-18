---
name: rails-testing-minitest
description: Minitest patterns for Rails — integration tests, fixtures. Load when test/ directory exists per stacks/rails profile.
user-invokable: false
---

# Rails Minitest patterns

Load when `test/` exists ([stacks/rails](../stacks/rails/profile.yaml) `if_test_dir`).

## Commands

`bundle exec rails test`, `rails test:system` when configured.

## Conventions

- Integration tests for controllers/routes; system tests for browser flows.
- Fixtures or factory gem per project convention — match existing style.
- Parallelize locally only if project CI supports it.

## Do not

- Mix RSpec and Minitest in new files — follow project standard.
