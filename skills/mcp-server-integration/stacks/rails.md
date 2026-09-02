# Rails MCP

- **SDK** — the official `mcp` gem (modelcontextprotocol/ruby-sdk); `fast-mcp` is the
  community alternative. A Node sidecar only when that is already the team standard.
- **Transport** — stdio for a locally launched server; a container in production is reachable
  only over **Streamable HTTP**, so pick the transport to match the deployment, not the reverse.
- **Tools** — one service object per tool; authorize with same policies as HTTP API.
- **Secrets** — MCP server runs with app credentials; no per-client API keys in repo.
- **Deploy** — systemd/Foreman locally; container with read-only FS in production when possible.
- **Docs** — list tools and required args in project README for agent operators.
