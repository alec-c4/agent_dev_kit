---
name: rails-core-patterns
description: Ruby on Rails patterns — compact namespacing, services, queries, N+1 avoidance. Load for Rails apps after stacks/rails profile.
user-invokable: false
---

# Rails core patterns

Load after [stacks/rails](../stacks/rails/SKILL.md). Tooling from `profile.yaml`.

**Frontend variant?** Check `skills_to_load` from detect-stack — importmap/Hotwire, API-only, jsbundling, or Inertia + React/Vue/Svelte (see [stacks/rails](../stacks/rails/SKILL.md)).

## Application structure

- **Compact namespacing:** `class Billing::InvoicePresenter` in `billing/invoice_presenter.rb` — no nested `module` / `class` blocks.
- **Controllers:** RESTful, thin — orchestration only; no business rules spanning multiple models inline.
- **Service objects:** `Billing::CreateInvoice.call(params)` for multi-step writes; return result object (`success?`, `errors`).
- **Query objects:** `Billing::InvoicesQuery.new(scope, filters).call` — complex filtering/sorting out of models.
- **Form objects:** `ActiveModel::Model` for non-ActiveRecord boundaries (API params, wizard steps).
- **Presenters / decorators:** view formatting out of models when project uses them — not mandatory for every field.

## Active Record

- **Validations** on model for single-record invariants; cross-model rules in services.
- **Callbacks** sparingly — prefer explicit service calls over `after_create` chains that hide side effects.
- **Scopes** named and composable; avoid default_scope unless team standard.
- **Enums** via `enum :status, ...` (Rails 7.1+ keyword syntax) when project uses enums.
- **No N+1:** `includes` / `preload` / `eager_load` — verify with Bullet in development ([profile dod_overlay](../stacks/rails/profile.yaml) `no_n_plus_one`).
- **Transactions:** `ActiveRecord::Base.transaction do` around multi-record writes; keep transactions short.

## Background and real-time

- **Active Job** with project adapter (Solid Queue, Sidekiq, etc.) — jobs idempotent where retries possible.
- **Action Cable** / Turbo Streams for live UI when using Hotwire — authorize channels per record.
- **Action Mailer** — deliver_later; templates in `app/views/*_mailer/`.

## Configuration and autoloading

- **Zeitwerk** — file path matches constant (`billing/invoice.rb` → `Billing::Invoice`).
- Secrets in **credentials** or ENV — never committed; `Rails.application.credentials` in code, not literals.
- Feature flags via project convention (Flipper, ENV) — document in plan when adding.

## Security

- **Strong parameters** in controllers; never `params.permit!` on user input.
- **Authorization** (Pundit/CanCan) before mutating or reading protected records — check in controller or service entry.
- **CSRF** on session-based HTML forms; API-only apps use token strategy per [rails-api](../rails-api/SKILL.md).

## i18n

- User-visible strings via `I18n.t` when project uses locales ([profile dod_overlay](../stacks/rails/profile.yaml) `i18n_user_strings`).
- Do not hardcode copy in mailers/views when `config/locales/` exists.

## Testing entry point

- `spec/` → [rails-testing-rspec](../rails-testing-rspec/SKILL.md); `test/` → [rails-testing-minitest](../rails-testing-minitest/SKILL.md).

## References

- [Rails guides](https://guides.rubyonrails.org/)
- [Active Record Query Interface](https://guides.rubyonrails.org/active_record_querying.html)
