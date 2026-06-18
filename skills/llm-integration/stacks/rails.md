# Rails LLM integration

- **Server-side only** — call providers from jobs/services; never expose API keys to Hotwire/JS.
- **Gems** — ruby-openai, anthropic, or vendor SDK behind `Llm::Client` service object.
- **ActiveJob** — long streams and batch embeds off the request cycle.
- **Logging** — redact prompts/responses in production logs; store audit ids not full text when PII.
- **Config** — `Rails.application.credentials` or ENV; per-environment model names.
