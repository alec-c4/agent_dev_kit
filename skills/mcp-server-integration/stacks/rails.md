# Rails MCP

- **Transport** — stdio Ruby MCP gem or separate Node sidecar if team standard.
- **Tools** — one service object per tool; authorize with same policies as HTTP API.
- **Secrets** — MCP server runs with app credentials; no per-client API keys in repo.
- **Deploy** — systemd/Foreman locally; container with read-only FS in production when possible.
- **Docs** — list tools and required args in project README for agent operators.
