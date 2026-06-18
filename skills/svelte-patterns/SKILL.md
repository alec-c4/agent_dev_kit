---
name: svelte-patterns
description: Svelte 5 patterns — runes, components, stores migration. Load after stacks/svelte profile.
user-invokable: false
---

# Svelte patterns

Load after [stacks/svelte](../stacks/svelte/SKILL.md).

## Svelte 5

- Prefer **runes** (`$state`, `$derived`, `$effect`) over legacy reactive statements when project uses Svelte 5.
- Keep components focused; lift shared logic to `.svelte.ts` modules when reused.

## Security

- `no_secrets_in_client` DoD — API keys and tokens stay in server/build env only.

## Testing

- Vitest + `@testing-library/svelte` when project uses them; commands from `profile.yaml`.

## References

- [Svelte docs](https://svelte.dev/docs)
