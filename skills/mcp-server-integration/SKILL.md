---
name: mcp-server-integration
description: Model Context Protocol servers — tools, resources, auth, and deployment per stack.
user-invocable: false
---

# MCP server integration

Use when exposing app capabilities to MCP clients (Cursor, Claude Desktop, etc.). Read `topic_files.mcp` from detect-stack.

## Universal

- **Least privilege** — each tool scoped to one action; validate args server-side.
- **No secrets in responses** — redact tokens and PII from tool output.
- **Transport** — the spec defines two: **stdio** for a client-launched local process, and
  **Streamable HTTP** for remote (one endpoint, replies as JSON or a request-scoped SSE
  stream). The separate HTTP+SSE transport of earlier revisions is gone. Remote means auth.
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
