---
name: rails-js-bundling
description: Rails jsbundling/cssbundling, esbuild, Vite, and Shakapacker patterns. Load when a JS bundler gem is present.
user-invokable: false
---

# Rails JS bundling

Load when `jsbundling-rails`, `vite_rails`, or `shakapacker` is in the Gemfile ([stacks/rails](../stacks/rails/profile.yaml) `if_gem`).

Used when the app **does not** rely on importmap alone — React/Vue/Svelte SPA islands, **Inertia**, or heavy npm dependencies.

## jsbundling-rails + esbuild (common)

- Install adds **`package.json`** scripts, typically `"build": "esbuild app/javascript/*.* --bundle --sourcemap --outdir=app/assets/builds"`.
- Entry: **`app/javascript/application.js`** imports pages/components; layout uses `javascript_include_tag "application", defer: true`.
- **`cssbundling-rails`** often paired — Tailwind/PostCSS via `yarn build:css` → `app/assets/builds/application.css`.
- **`bin/dev`** runs Foreman/Overmind with `web` + `js` + `css` processes — use in development.

## Vite (`vite_rails`)

- **`vite.config.ts`** at root; entries under `app/frontend/` or `app/javascript/`.
- Layout: **`vite_client_tag`** + **`vite_javascript_tag 'application'`** (names per project).
- HMR via Vite dev server; production **`bin/vite build`** in CI before `assets:precompile` or deploy step.
- Env vars: only `VITE_*` exposed to client — never secrets.

## Shakapacker (Webpack)

- **`config/webpack/`** + **`config/shakapacker.yml`** — follow generated README.
- **`javascript_pack_tag`** in layout; packs under `app/javascript/packs/`.
- Prefer migration path to Vite/jsbundling for new features when team allows.

## Rails integration

- **Propshaft/Sprockets** serves built files from `app/assets/builds/` — commit builds in CI, not necessarily in git (team policy).
- **`app/assets/config/manifest.js`** links built assets when using Sprockets-style manifest.
- Pin **Node** in `.node-version` / `engines`; CI uses same major version.

## With Inertia

- Page components: `app/javascript/Pages/` (React/Vue) or `app/frontend/pages/` (Svelte/Inertia conventions vary).
- Load [inertia](../inertia/SKILL.md) + framework skill (`svelte-patterns`, etc.).
- Single layout ERB with Inertia root — no duplicate client-side routers.

## Do not

- Run importmap and jsbundling for the **same** entrypoint without migration docs.
- Commit `node_modules`; document `yarn install` / `npm ci` in CI and README.

## References

- [jsbundling-rails](https://github.com/rails/jsbundling-rails)
- [cssbundling-rails](https://github.com/rails/cssbundling-rails)
- [Vite Ruby](https://vite-ruby.netlify.app/)
