---
name: react-patterns
description: React patterns for Rails Inertia, jsbundling, or SPA islands — components, hooks, state. Load when @inertiajs/react or React in package.json on Rails.
user-invokable: false
---

# React patterns (Rails / Inertia context)

Load with [inertia](../inertia/SKILL.md) on Rails when `@inertiajs/react` is present, or with [rails-js-bundling](../rails-js-bundling/SKILL.md) for bundled React.

## Components

- Functional components and hooks; colocate small helpers — avoid mega-files.
- **Props** typed (TypeScript when project uses it); validate server props shape matches Inertia page contract.

## Inertia + Rails

- Page components under project convention (`app/javascript/Pages/` or `app/frontend/pages/`).
- Use Inertia `Link`, `router`, `useForm` — do not duplicate Rails routes in client-only routers unless documented (e.g. hybrid).

## State and data

- Server remains source of truth for authoritative data; client state for UI-only concerns.
- No secrets in React bundle — env via Rails/Inertia shared props only for non-sensitive config.

## Testing

- Vitest/Jest + Testing Library when project uses them; request specs on Rails for Inertia props.

## References

- [Inertia.js — React](https://inertiajs.com/client-side-setup#react)
- [React docs](https://react.dev/)
