---
name: mcp-server-integration
description: Model Context Protocol servers — tools, resources, auth, and deployment per stack.
user-invokable: false
---

# MCP server integration

Use when exposing app capabilities to MCP clients (Cursor, Claude Desktop, etc.). Read `topic_files.mcp` from detect-stack.

## Universal

- **Least privilege** — each tool scoped to one action; validate args server-side.
- **No secrets in responses** — redact tokens and PII from tool output.
- **Transport** — stdio for local dev; HTTP/SSE only with auth when remote.
- **Versioning** — breaking tool schema changes need a major bump or new tool name.
- **Observability** — structured logs per tool call; rate-limit public endpoints.

Official spec: [Model Context Protocol](https://modelcontextprotocol.io/).

## Stack reference

| Stack family | File |
|--------------|------|
| Rails | [stacks/rails.md](stacks/rails.md) |
| Node / Next / Nuxt / Svelte | [stacks/node.md](stacks/node.md) |
| Python / FastAPI | [stacks/python.md](stacks/python.md) |
| Elixir / Phoenix | [stacks/elixir.md](stacks/elixir.md) |

Match the language SDK already used in the repo (`@modelcontextprotocol/sdk`, etc.).
