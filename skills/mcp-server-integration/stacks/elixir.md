# Elixir MCP

- **Transport** — stdio server process; supervise under release when needed.
- **Tools** — thin wrappers around context functions; pass tenant from MCP session config.
- **JSON** — Jason encode/decode; schema validate with NimbleOptions where helpful.
- **Observability** — Logger metadata per tool invocation.
- **Tests** — ExUnit driving stdin/stdout protocol fixtures.
