---
name: rails-js-bundling
description: Rails jsbundling/cssbundling, esbuild, Vite, and Shakapacker patterns. Load when a JS bundler gem is present.
user-invokable: false
---

# Rails JS bundling

Load when `jsbundling-rails`, `vite_rails`, or `shakapacker` is in the Gemfile ([stacks/rails](../stacks/rails/profile.yaml) `if_gem`).

Used when the app **does not** rely on importmap alone — React/Vue/Svelte SPA islands, Inertia, or heavy npm dependencies.

## Build pipeline

- **`jsbundling-rails`** — esbuild, rollup, or webpack via `package.json` scripts; entry in `app/javascript/application.js`.
- **`cssbundling-rails`** — often paired; Tailwind/PostCSS via npm, not Sprockets-only.
- **`vite_rails` / `vite-plugin-rails`** — Vite dev server + manifest; prefer Vite docs for HMR and env.
- **`shakapacker`** — Webpack-based; legacy/new apps migrating off Webpacker — follow project README.

## Rails integration

- **`javascript_include_tag`** / **`vite_javascript_tag`** / Shakapacker helpers in layout — one canonical tag per layout.
- Run **`bin/dev`** (or documented npm script) in development; CI runs `assets:precompile` or `vite build` as per stack.
- Keep **Node version** pinned (`.node-version` / `engines` in `package.json`).

## With Inertia or SPA frontends

- Frontend source often under `app/javascript/` or `app/frontend/` — match project layout.
- Load [inertia](../inertia/SKILL.md) when `inertia_rails` is present; load framework pattern skills from `skills_to_load` (React, Vue, Svelte).

## Do not

- Commit `node_modules` or compiled packs without CI rebuild path documented.
- Duplicate asset pipelines (importmap + bundler) without migration notes.

## References

- [JS Bundling in Rails](https://github.com/rails/jsbundling-rails)
- [Vite Ruby](https://vite-ruby.netlify.app/)
