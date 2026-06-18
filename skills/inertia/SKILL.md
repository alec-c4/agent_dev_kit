---
name: inertia
description: Inertia.js patterns with Rails or Node backends. Load when inertia_rails or @inertiajs present per stack profile.
user-invokable: false
---

# Inertia.js patterns

Load when Inertia gem/package detected ([stacks/rails](../stacks/rails/profile.yaml) `if_gem: inertia_rails` or Node stack).

Inertia is a **protocol** between server and SPA: server returns JSON page object `{ component, props, url, version }` — not a separate REST API for each screen.

## Stack pairing (Rails)

| Frontend | package.json | Skills |
|----------|--------------|--------|
| React | `@inertiajs/react` | [react-patterns](../react-patterns/SKILL.md) |
| Vue 3 | `@inertiajs/vue3` | [vue-patterns](../vue-patterns/SKILL.md) |
| Svelte | `@inertiajs/svelte` | [svelte-patterns](../svelte-patterns/SKILL.md) |

Requires [rails-js-bundling](../rails-js-bundling/SKILL.md) (esbuild/Vite) — **not** importmap-only.

## Rails server setup

- Gem **`inertia_rails`** — controller inherits `InertiaController` or includes `InertiaRails::Controller`.
- Render pages: `render inertia: 'Dashboard/Index', props: { user: user.as_json(only: [...]) }`.
- **Root template** — single ERB (`app/views/layouts/application.html.erb`) with `<%= inertia_root %>` or Vite tags + Inertia mount point.
- **`inertia_share`** in `ApplicationController` for auth user, flash, locale — keep payloads small.
- **Flash** — map Rails flash to Inertia shared prop or use `redirect_back` with flash; client reads on next visit.
- **Validation errors** — return `422` with `errors` prop; client `useForm` displays field errors.
- **Authorization** — enforce in Rails before `render inertia:`; never rely on hiding props alone.

## Rails routing

- Standard REST routes → controller actions → Inertia render — no parallel JSON API for the same page data unless mobile clients need it.
- **Redirects** — `redirect_to users_path` works; Inertia follows X-Inertia requests.
- **Partial reloads** — `only: [:users, 'auth.user']` on visits to refetch subset of props (document in plan when used).

## Client bootstrap (all frameworks)

- **`createInertiaApp`** — resolve page components (glob import or manual map).
- **`@inertiajs/core`** — `router.visit`, `router.reload`, `preserveState`, `preserveScroll` — use intentionally on filters/pagination.
- **`Link`** component — Inertia navigation, not raw `<a href>` for internal routes (except external).
- **`useForm`** — posts to Rails with `_method`, CSRF via meta tag or Inertia Rails helper.
- **Version** — `InertiaRails.configure` / client `version` for asset cache busting on deploy.

## Svelte + Inertia (Rails)

See [svelte-patterns](../svelte-patterns/SKILL.md) § Inertia.

- Package: `@inertiajs/svelte` + Svelte 5.
- Pages: `resources/js/Pages/.../*.svelte` or `app/frontend/pages/` — match project glob in `createInertiaApp`.
- Props: typed via `PageProps` generic or JSDoc; server is source of truth.
- Layouts: Svelte layout components wrapping `{@render children()}` or slot pattern per Svelte version.
- Forms: `import { useForm } from '@inertiajs/svelte'` — bind to inputs, `form.post(route)`.

## Testing

- **Request specs:** assert `X-Inertia` response, component name (e.g. `Dashboard/Index`), and key props — not full JSON snapshots.
- **System/feature tests:** optional for critical flows when Capybara + JS driver configured.
- Client unit tests (Vitest) for presentational components with mocked props.

## Do not

- Expose secrets in shared props or page props sent to client.
- Build client-only routing that duplicates Rails routes without documented hybrid reason.
- Return HTML error pages on Inertia requests — use Inertia error handling / dedicated error pages.

## References

- [Inertia.js](https://inertiajs.com/)
- [inertia_rails](https://github.com/inertiajs/inertia-rails)
- [Inertia — Svelte](https://inertiajs.com/client-side-setup#svelte)
