---
name: rails-testing-rspec
description: RSpec patterns for Rails — request specs, factories, system tests. Load when spec/ directory exists per stacks/rails profile.
user-invokable: false
---

# Rails RSpec patterns

Load when `spec/` exists ([stacks/rails](../stacks/rails/profile.yaml) `if_spec_dir`).

## Commands

From stack profile:

```bash
bundle exec rspec
bundle exec rspec spec/requests/users_spec.rb
bundle exec rspec --format documentation
```

## Layout

| Directory | Use for |
|-----------|---------|
| `spec/models/` | Validations, scopes, model methods |
| `spec/requests/` | HTTP/API, Inertia, Turbo Stream responses |
| `spec/system/` | Browser flows (Capybara + JS driver) |
| `spec/services/` | Service object behaviour |
| `spec/jobs/` | Active Job perform/enqueue |

## Factories and data

- **FactoryBot** — `create(:user)` / `build`; **traits** for variants (`:admin`, `:with_invoice`).
- **Let / let!** — lazy vs eager; avoid shared mutable `@ivars` across examples.
- **Database Cleaner** or transactional fixtures — match project config; examples isolated.

## Request specs

- **`sign_in user`** (Devise test helper) or auth header setup in shared context.
- Assert **status**, response body keys, and headers — not implementation details.
- **Inertia:** `expect(inertia.component).to eq 'Dashboard/Index'` (inertia_rails test helpers when available) or parse JSON page object.
- **Turbo Stream:** `expect(response.media_type).to eq 'text/vnd.turbo-stream.html'`.
- **API:** parse JSON; assert error structure on 422/403.

## System specs

- **js: true** driver for Hotwire/Inertia flows that need JavaScript.
- Use **stable selectors** (`data-testid` or roles) — avoid brittle CSS chains.
- Keep count low — cover critical paths only; rest in request specs.

## External HTTP

- **WebMock / VCR** — stub or record third-party calls; no live network in CI.

## Mapping to specs

- Tag examples with **AC IDs** from `.ai/specs/*-spec.md` in description or comment when plan requires traceability.

## Do not

- Test Rails framework internals or private methods without reason.
- Mix RSpec into `test/` Minitest tree — follow project standard.

## References

- [RSpec Rails](https://github.com/rspec/rspec-rails)
- [FactoryBot](https://github.com/thoughtbot/factory_bot)
