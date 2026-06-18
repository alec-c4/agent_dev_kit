---
name: rails-importmaps
description: Rails importmap-rails patterns — pin modules, Stimulus, no Node bundler. Load when importmap-rails gem present.
user-invokable: false
---

# Rails importmaps

Load when `importmap-rails` is in the Gemfile ([stacks/rails](../stacks/rails/profile.yaml) `if_gem`).

Typical stack: **Hotwire (Turbo + Stimulus) + importmap** — no Webpack/Vite/esbuild pipeline.

## Assets

- Pin modules in `config/importmap.rb` — prefer `pin` / `pin_all_from` over vendoring without version.
- **Stimulus** controllers in `app/javascript/controllers/` — loaded via importmap, not bundled.
- Use **`javascript_importmap_tags`** in layout; avoid adding a Node bundler unless the team explicitly migrates to jsbundling/vite.

## When paired with Hotwire

- See [hotwire](../hotwire/SKILL.md) for Turbo Frames/Streams and Stimulus conventions.
- Turbo Drive + importmap is the default Rails 7+ full-stack path without `jsbundling-rails`.

## Do not

- Mix importmap with a second JS bundler for the same entrypoint without a documented migration plan.
- Put secrets or API keys in `app/javascript` — server-rendered config or meta tags with CSP.

## References

- [Importmap for Rails](https://github.com/rails/importmap-rails)
- [Hotwire](https://hotwired.dev/)
