# Node LLM integration

- **Vercel AI SDK** or official provider SDK in Route Handlers / server actions only.
- **Streaming** — use framework streaming helpers; set timeouts on edge/server functions.
- **Env** — `process.env` on server; never `NEXT_PUBLIC_*` for provider keys.
- **Structured output** — Zod + `generateObject` or equivalent schema validation.
- **Rate limits** — per-user quotas on expensive endpoints.
