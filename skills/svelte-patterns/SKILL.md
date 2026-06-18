---
name: svelte-patterns
description: Svelte 5 patterns — runes, components, Inertia adapter. Load after stacks/svelte profile or with Inertia on Rails.
user-invokable: false
---

# Svelte patterns

Load after [stacks/svelte](../stacks/svelte/SKILL.md) or with [inertia](../inertia/SKILL.md) when `@inertiajs/svelte` is in `package.json`.

## Svelte 5 runes

- **`$state`** — reactive local state; prefer over legacy `let x` + reactive statements in Svelte 5 projects.
- **`$derived`** — computed values from state; keep expressions pure (no side effects).
- **`$effect`** — sync with external systems; return cleanup function when subscribing (timers, listeners).
- **`$props()`** — declare props with types in `.svelte` or `interface Props` + `$props()` destructuring.
- **`$bindable`** — two-way binding only when parent-child contract requires it; default one-way data flow.

## Components

- **One component per file** — PascalCase filename matches default export usage.
- **Snippets** (`{#snippet}` / `{@render}`) for reusable markup regions in Svelte 5.
- Lift reusable logic to **`.svelte.ts` modules** (runes in `.svelte.ts` when using runes mode).
- Keep components small — extract when template + script exceeds ~150 lines or duplicates appear twice.

## Events and DOM

- Prefer **`onclick`** / native events over legacy `on:click` in Svelte 5 unless project still on legacy syntax.
- **`bind:this`** for imperative APIs (focus, chart libs) — document why imperative access is needed.
- Accessibility: semantic HTML, `aria-*` on interactive widgets, keyboard handlers for custom controls.

## Stores (legacy / shared)

- Prefer runes + context for new code; **`writable`/`derived` stores** only when matching existing codebase patterns.
- **`setContext` / `getContext`** for subtree state (auth shell, theme) — typed keys in `.svelte.ts`.

## Inertia + Svelte (Rails or Vite SPA)

When `@inertiajs/svelte` is present:

- **Pages** live under project glob (e.g. `resources/js/Pages/**/*.svelte`) — resolved in `createInertiaApp`.
- **Props** arrive from Rails via Inertia — treat as read-only input; use `$derived` from `$props()` for computed UI state.
- **`useForm`** from `@inertiajs/svelte` for POST/PATCH/DELETE — display `form.errors`, `form.processing`, disable submit while processing.
- **`Link`** from `@inertiajs/svelte` for in-app navigation — preserves SPA behaviour and scroll/state options.
- **`router.visit` / `router.reload`** — partial reloads with `only: ['propName']` when documented in spec.
- Do **not** duplicate Rails routes in a client router unless hybrid mode is explicit in project docs.

## Security

- **`no_secrets_in_client`** DoD ([stacks/svelte](../stacks/svelte/profile.yaml)) — API keys only in server env; Vite exposes `VITE_*` to bundle by design.
- Sanitize user HTML — avoid `{@html}` unless content is trusted or sanitized server-side.

## Testing

- **Vitest** + **`@testing-library/svelte`** when project uses them — render with props, assert DOM and events.
- Commands from stack profile: `npm test`, `npm run check` (svelte-check).
- Inertia pages: mock page props; integration covered by Rails request specs per [inertia](../inertia/SKILL.md).

## Tooling

- Run **`svelte-check`** before PR when profile lists `npm run check`.
- ESLint with `eslint-plugin-svelte` when configured — fix new warnings in touched files.

## References

- [Svelte 5 docs](https://svelte.dev/docs/svelte/overview)
- [Svelte runes](https://svelte.dev/docs/svelte/what-are-runes)
- [Inertia — Svelte](https://inertiajs.com/client-side-setup#svelte)
