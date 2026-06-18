---
name: inertia
description: Inertia.js patterns with Rails or Node backends. Load when inertia_rails or @inertiajs present per stack profile.
user-invokable: false
---

# Inertia.js patterns

Load when Inertia gem/package detected ([stacks/rails](../stacks/rails/profile.yaml) `if_gem: inertia_rails` or Node stack).

## Rails variants

| Frontend | package.json signal | Also load |
|----------|---------------------|-----------|
| React | `@inertiajs/react` | [react-patterns](../react-patterns/SKILL.md) |
| Vue 3 | `@inertiajs/vue3` | [vue-patterns](../vue-patterns/SKILL.md) |
| Svelte | `@inertiajs/svelte` | [svelte-patterns](../svelte-patterns/SKILL.md) |

Rails often pairs Inertia with **jsbundling/esbuild** or **Vite** — see [rails-js-bundling](../rails-js-bundling/SKILL.md). Not used with **importmap-only** stacks.

## Server

- Return `Inertia.render` with props — no duplicate REST API for same page data unless needed for mobile/API clients.
- Shared data via `inertia_share`; flash via session.

## Client

- Page components colocated with framework (React/Vue/Svelte) per project layout.
- Preserve `preserveState` / `preserveScroll` intentionally on pagination filters.

## Testing

- Request specs assert Inertia component name and key props — avoid snapshotting entire JSON blobs.
