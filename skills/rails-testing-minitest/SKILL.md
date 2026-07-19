---
name: rails-testing-minitest
description: Minitest patterns for Rails — integration tests, fixtures. Load when test/ directory exists per stacks/rails profile.
user-invokable: false
---

# Rails Minitest patterns

Load when `test/` exists ([stacks/rails](../stacks/rails/profile.yaml) `if_test_dir`).

## Commands

```bash
bundle exec rails test
bundle exec rails test test/controllers/users_controller_test.rb
bundle exec rails test:system
```

## Layout

| Directory | Use for |
|-----------|---------|
| `test/models/` | Model validations and methods |
| `test/controllers/` or `test/integration/` | HTTP endpoints (prefer integration for full stack) |
| `test/system/` | Capybara browser tests |
| `test/jobs/` | Job enqueue/perform |

## Style

- **`ActiveSupport::TestCase`** for models; **`ActionDispatch::IntegrationTest`** for requests.
- **Fixtures** (`test/fixtures/*.yml`) when project uses them; **factory gem** when project already uses one — do not introduce second style.
- **`setup` / `teardown`** for common auth and data — keep tests independent.

## Integration tests

- **`log_in_as(user)`** helper or session setup per project.
- Assert **`assert_response :success`**, **`assert_redirected_to`**, parsed JSON for API.
- **Inertia:** assert response body includes component key or use inertia_rails test assertions if configured.

## System tests

- **`driven_by :selenium`** or project driver — use for Turbo/Inertia JS paths sparingly.
- **`assert_selector`** with accessible roles/labels where possible.

## Parallelization

- **`parallelize(workers: :number_of_processors)`** in `test_helper.rb` when CI supports it — match team config.

## Do not

- Add RSpec files under `spec/` in a Minitest project.
- Depend on test order — each test self-contained.

## References

- [Testing Rails applications](https://guides.rubyonrails.org/testing.html)
