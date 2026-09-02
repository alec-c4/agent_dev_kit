---
name: nuxt-patterns
description: Nuxt patterns — server routes, composables, SSR boundaries. Load after stacks/nuxt profile.
user-invocable: false
---

# Nuxt patterns

Load after [stacks/nuxt](../stacks/nuxt/SKILL.md).

## Structure

- **Composables** for shared state and data fetching; `useFetch` / `useAsyncData` with keyed cache.
- **Server routes** in `server/api/` for secrets and backend integration.
- **Layouts** and **middleware** for auth gates — do not duplicate in every page.

## SSR and client

- Respect `server_client_boundary` DoD — no server secrets in client composables.
- Run the typecheck command from `profile.yaml` before PR — Nuxt 4 uses `nuxt prepare && vue-tsc -b --noEmit`; `nuxi typecheck` is the Nuxt 3 form.

## References

- [Nuxt docs](https://nuxt.com/docs)
