---
name: elixir-phoenix-patterns
description: Elixir and Phoenix patterns — contexts, Ecto, LiveView. Load after stacks/elixir profile.
user-invokable: false
---

# Elixir / Phoenix patterns

Load after [stacks/elixir](../stacks/elixir/SKILL.md).

## Contexts

- **Context modules** own business logic; schemas for Ecto changesets.
- **LiveView** for interactive UI — assign minimal state; handle `handle_info` carefully.

## Ecto

- Preload associations explicitly ([profile dod_overlay](../stacks/elixir/profile.yaml) `ecto_preload`).
- Transactions via `Repo.transaction/1` for multi-step writes.

## Testing

- `mix test` with ExUnit; LiveView tests via `Phoenix.LiveViewTest`.

## References

- [Phoenix docs](https://hexdocs.pm/phoenix/overview.html)
