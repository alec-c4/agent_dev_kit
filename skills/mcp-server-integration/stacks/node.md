# Node MCP

- **SDK** — `@modelcontextprotocol/sdk` in a dedicated `packages/mcp-server` or `scripts/mcp/`.
- **Tools** — Zod schemas for inputs; map to existing REST handlers or services.
- **stdio** — default for a locally launched server; log to stderr only, never stdout.
- **Streamable HTTP** — the remote binding; require auth, never anonymous write tools.
- **Build** — bundle with tsx/tsup; pin SDK version in lockfile.
