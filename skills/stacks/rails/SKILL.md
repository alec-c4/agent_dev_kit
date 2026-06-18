---
name: stacks/rails
description: Stack profile for Ruby on Rails — tooling, DoD overlay, and skill routing.
user-invokable: false
---

# Ruby on Rails

Machine-readable profile: `profile.yaml` in this directory (loaded by `detect-stack.sh`).

## When to read

After stack detection resolves `rails`, read this skill for tooling commands, stack-specific DoD, and pattern skills to load.

## Rails UI / frontend variants

Detection adds pattern skills conditionally — not every app loads every skill.

| Variant | Signal | Pattern skills |
|---------|--------|----------------|
| **Importmap + Hotwire** | `importmap-rails`, often `turbo-rails` | `rails-importmaps`, `hotwire` |
| **JS bundler** | `jsbundling-rails`, `vite_rails`, `shakapacker` | `rails-js-bundling` |
| **Inertia SPA** | `inertia_rails` + `package.json` | `inertia` + frontend patterns (React/Vue/Svelte) |
| **API-only** | `config.api_only = true` in `config/application.rb` | `rails-api` |

Full-stack Rails may combine **Hotwire + importmap** (classic default) or **Inertia + esbuild/Vite**. API-only skips HTML/Hotwire skills when `api_only` is detected.

## Source of truth

`profile.yaml` — test/lint/security commands, `skills` routing, `dod_overlay`, `mcp_suggest`.
