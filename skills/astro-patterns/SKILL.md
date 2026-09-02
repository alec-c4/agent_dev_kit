---
name: astro-patterns
description: Astro patterns — content collections, islands, SSR/SSG boundaries. Load after stacks/astro profile.
user-invocable: false
---

# Astro patterns

Load after [stacks/astro](../stacks/astro/SKILL.md).

## Structure

- **Content collections** for blog/docs with typed schemas in `src/content.config.ts`;
  each collection declares a `loader` (Content Layer) plus a Zod `schema`.
- **Layouts** for shared chrome; pages stay thin.
- **Components** — static by default; add client directives only when interactivity is required.

## Rendering

- Prefer **SSG** for content; use SSR routes only when per-request data is required.
- Server endpoints in `src/pages/api/` for secrets and dynamic backends — never expose keys to client islands.

## Assets and performance

- Images via `astro:assets` — `<Image />`, `<Picture />` for multiple formats, `getImage()`
  outside HTML. The `@astrojs/image` integration is deprecated. Lazy-load heavy client islands.
- Run `astro check` and project typecheck from stack profile before PR.

## References

- [Astro docs](https://docs.astro.build/)
