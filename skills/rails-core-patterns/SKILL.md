---
name: rails-core-patterns
description: Ruby on Rails patterns — compact namespacing, services, queries, N+1 avoidance. Load for Rails apps after stacks/rails profile.
user-invokable: false
---

# Rails core patterns

Load after [stacks/rails](../stacks/rails/SKILL.md). Tooling from `profile.yaml`.

## Structure

- **Compact namespacing:** `class Billing::InvoicePresenter` in `billing/invoice_presenter.rb` — no nested `module` blocks.
- **Service objects:** `Billing::CreateInvoice` for multi-step writes; keep controllers thin.
- **Query objects:** complex scopes in dedicated classes, not 200-line models.
- **Forms:** `ActiveModel::Model` or dedicated form objects for non-AR boundaries.

## Data access

- **No N+1:** `includes` / `preload` / `eager_load` — verify with stack profiler or bullet in dev.
- **Transactions:** wrap multi-record writes; avoid long transactions holding locks.

## Security and i18n

- Strong params; authorize with policy layer (Pundit/CanCan) when project uses it.
- User-visible strings via i18n when project uses locales ([profile dod_overlay](../stacks/rails/profile.yaml)).

## References

- [Rails guides](https://guides.rubyonrails.org/)
- Project `AGENTS.md` and guidelines — no stack detail duplicated there.
