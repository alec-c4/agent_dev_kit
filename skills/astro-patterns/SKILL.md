---
name: astro-patterns
description: Astro patterns — content collections, islands, SSR/SSG boundaries. Load after stacks/astro profile.
user-invokable: false
---

# Astro patterns

Load after [stacks/astro](../stacks/astro/SKILL.md).

## Structure

- **Content collections** for blog/docs with typed schemas (`src/content/config.ts`).
- **Layouts** for shared chrome; pages stay thin.
- **Components** — static by default; add client directives only when interactivity is required.

## Rendering

- Prefer **SSG** for content; use SSR routes only when per-request data is required.
- Server endpoints in `src/pages/api/` for secrets and dynamic backends — never expose keys to client islands.

## Assets and performance

- Use `@astrojs/image` or built-in assets when available; lazy-load heavy client islands.
- Run `astro check` and project typecheck from stack profile before PR.

## References

- [Astro docs](https://docs.astro.build/)
