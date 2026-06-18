---
name: vue-patterns
description: Vue 3 patterns for Rails Inertia or bundled frontends. Load when @inertiajs/vue3 present.
user-invokable: false
---

# Vue patterns (Rails / Inertia context)

Load with [inertia](../inertia/SKILL.md) when `@inertiajs/vue3` is in `package.json`.

## Components

- **Composition API** with `<script setup>` when project uses Vue 3 defaults.
- Page components colocated per project (`app/javascript/Pages/` or equivalent).

## Inertia + Rails

- Use Inertia `Link`, `router`, `useForm` from `@inertiajs/vue3`.
- Shared layouts as Vue layouts; preserve scroll/state intentionally on filters and pagination.

## State and data

- Authoritative data from Rails via Inertia props; Pinia/Vuex only for client UI state when already in project.

## Testing

- Vitest + Vue Test Utils when configured; Rails request specs for Inertia component + props.

## References

- [Inertia.js — Vue](https://inertiajs.com/client-side-setup#vue)
- [Vue docs](https://vuejs.org/)
