---
name: sveltekit-patterns
description: SvelteKit patterns — load functions, form actions, hooks. Load after stacks/sveltekit profile.
user-invokable: false
---

# SvelteKit patterns

Load after [stacks/sveltekit](../stacks/sveltekit/SKILL.md).

## Routing and data

- **`+page.server.ts`** for secrets and DB; **`+page.ts`** for public load when safe.
- **Form actions** for mutations with progressive enhancement.
- **`hooks.server.ts`** for auth/session — fail closed.

## Boundaries

- `server_client_boundary` DoD — type-safe `$env/static/private` vs public modules.

## References

- [SvelteKit docs](https://svelte.dev/docs/kit)
