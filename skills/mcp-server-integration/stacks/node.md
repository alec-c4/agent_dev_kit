# Node MCP

- **SDK** — `@modelcontextprotocol/sdk` in a dedicated `packages/mcp-server` or `scripts/mcp/`.
- **Tools** — Zod schemas for inputs; map to existing REST handlers or services.
- **stdio** — default for Cursor/Claude Desktop; log to stderr only.
- **Auth** — if HTTP transport, bearer token or mTLS; never anonymous write tools.
- **Build** — bundle with tsx/tsup; pin SDK version in lockfile.
