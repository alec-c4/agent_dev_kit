---
name: nextjs-patterns
description: Next.js App Router patterns — RSC boundaries, caching, server actions. Load after stacks/nextjs profile.
user-invokable: false
---

# Next.js patterns

Load after [stacks/nextjs](../stacks/nextjs/SKILL.md). Commands from `profile.yaml`.

## App Router

- Default to **Server Components**; add `"use client"` only for interactivity.
- **Colocate** loading/error boundaries with route segments.
- **Server Actions** for mutations — validate input server-side; revalidate tags/paths explicitly.

## Data and caching

- Prefer `fetch` cache options and `unstable_cache` / Cache Components per project Next version docs.
- Do not leak secrets into client bundles — env vars without `NEXT_PUBLIC_` stay server-only.

## DoD alignment

- `server_client_boundary` and `no_any_public_api` from stack `dod_overlay`.

## References

- [Next.js docs](https://nextjs.org/docs)
