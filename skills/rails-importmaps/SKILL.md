---
name: rails-importmaps
description: Rails importmap-rails patterns — pin modules, Stimulus, no Node bundler. Load when importmap-rails gem present.
user-invokable: false
---

# Rails importmaps

Load when `importmap-rails` is in the Gemfile ([stacks/rails](../stacks/rails/profile.yaml) `if_gem`).

Typical stack: **Hotwire (Turbo + Stimulus) + importmap** — no Webpack/Vite/esbuild pipeline.

## Setup

- **`config/importmap.rb`** — single source of pinned modules; run `bin/importmap json` to inspect resolved URLs.
- Layout includes **`javascript_importmap_tags`** (and **`javascript_include_tag "application"`** when using Sprockets/propshaft entry).
- Stimulus controllers live in `app/javascript/controllers/` — pinned via `pin_all_from` under `app/javascript`.

## Pinning

- Prefer **`pin "package"`** from CDN (jspm/skypack) or **`pin_all_from`** for local files — avoid vendoring minified third-party blobs in repo without version pin.
- Preload critical modules: `pin "@hotwired/turbo-rails", preload: true`.
- After adding npm-free pins, **`bin/importmap audit`** when available — track security advisories.

## With Hotwire

- Load [hotwire](../hotwire/SKILL.md) when `turbo-rails` is present — Turbo + Stimulus is the default Rails 7+ full-stack path.
- Do not add `jsbundling-rails` for the same entrypoint without a documented migration.

## ESM in Rails

- Use **`import`** syntax in `app/javascript/application.js`; no `require()` unless legacy shim documented.
- **`config/importmap.rb`** must expose every bare specifier used in import statements.

## Do not

- Mix importmap with a second JS bundler for the same entrypoint without migration plan.
- Put secrets or API keys in `app/javascript` — use server-rendered data attributes or meta tags with CSP.

## References

- [Importmap for Rails](https://github.com/rails/importmap-rails)
- [Working with JavaScript](https://guides.rubyonrails.org/working_with_javascript.html)
