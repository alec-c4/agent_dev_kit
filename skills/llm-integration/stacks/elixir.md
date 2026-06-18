# Elixir LLM integration

- **Req / Finch** — HTTP clients with receive timeouts; isolate provider modules.
- **OTP** — supervised tasks for streaming; back-pressure on large responses.
- **Config** — runtime.exs / env for API keys and model names.
- **Telemetry** — `:telemetry` events for token usage and latency.
- **Tests** — Bypass/Mox for HTTP; no network in CI.
