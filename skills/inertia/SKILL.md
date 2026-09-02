---
name: inertia
description: Inertia.js patterns with Rails or Node backends. Load when inertia_rails or @inertiajs present per stack profile.
user-invocable: false
---

# Inertia.js patterns

Load when Inertia gem/package detected ([stacks/rails](../stacks/rails/profile.yaml) `if_gem: inertia_rails` or Node/Laravel stack).

Inertia is a **protocol** between server and SPA: the server returns a JSON page object `{ component, props, url, version }` — not a separate REST API for each screen.

## Server (any backend)

- Render with the framework adapter (`Inertia.render` in Rails, equivalent in Node/PHP).
- **Props** — only what the page needs; authorize before render.
- **Shared data** (auth user, flash, locale) via adapter «share» hook — keep payloads small.
- **Validation errors** — return `422` with field errors; client forms display them.
- **Redirects** — standard HTTP redirects; Inertia follows on `X-Inertia` requests.
- **Partial reloads** — refetch subset of props with `only` when documented in spec.

## Client bootstrap

- **`createInertiaApp`** — resolve page components (glob import or manual map).
- **`Link`** — Inertia navigation for internal routes; preserve scroll/state options intentionally.
- **`useForm`** — POST/PATCH/DELETE with processing state and field errors.
- **`router.visit` / `router.reload`** — explicit navigation; use `preserveState` / `preserveScroll` on filters and pagination.
- **Version** — asset cache busting on deploy (adapter + client `version` config).

## Svelte adapter

Load [svelte-patterns](../svelte-patterns/SKILL.md) when `@inertiajs/svelte` is in `package.json`.

- Pages under project glob (e.g. `resources/js/Pages/**/*.svelte`) — wired in `createInertiaApp`.
- Props from server via `$props()` — treat as read-only; `$derived` for UI-only state.
- **`useForm`** from `@inertiajs/svelte` — `form.errors`, `form.processing`, disable submit while in flight.
- **`Link`** from `@inertiajs/svelte` for in-app navigation.

## React and Vue

- React: `@inertiajs/react` — page components + `useForm` / `Link` from that package.
- Vue 3: `@inertiajs/vue3` — `<script setup>` pages + composition API helpers.

## Testing

- **Server:** assert Inertia response (component name, key props) — avoid full JSON snapshots.
- **Client:** unit-test components with mocked props (Vitest + Testing Library).

## Do not

- Expose secrets in page or shared props.
- Build a parallel client-side router duplicating server routes without documented hybrid reason.
- Return HTML error pages on Inertia XHR requests — use Inertia error handling.

## References

- [Inertia.js](https://inertiajs.com/)
- [Inertia — Svelte](https://inertiajs.com/client-side-setup#svelte)
