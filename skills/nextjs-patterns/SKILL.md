---
name: nextjs-patterns
description: Next.js App Router patterns — RSC boundaries, caching, server actions. Load after stacks/nextjs profile.
user-invocable: false
---

# Next.js patterns

Load after [stacks/nextjs](../stacks/nextjs/SKILL.md). Commands from `profile.yaml`.

## App Router

- Default to **Server Components**; add `"use client"` only for interactivity.
- **Colocate** loading/error boundaries with route segments.
- **Server Actions** for mutations — validate input server-side; revalidate tags/paths explicitly.

## Data and caching

- Prefer `fetch` cache options; for cached work use the `use cache` directive with `cacheLife` / `cacheTag` on versions that ship Cache Components, and `unstable_cache` only on older ones. Check the project's Next version before choosing.
- Do not leak secrets into client bundles — env vars without `NEXT_PUBLIC_` stay server-only.

## DoD alignment

- `server_client_boundary` and `no_any_public_api` from stack `dod_overlay`.

## References

- [Next.js docs](https://nextjs.org/docs)
