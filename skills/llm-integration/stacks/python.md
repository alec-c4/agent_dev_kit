# Python LLM integration

- **Async** — FastAPI background tasks or Celery for long completions.
- **SDKs** — OpenAI/Anthropic official clients; LangChain only if already in project.
- **Pydantic** — response models for tool calls and JSON mode.
- **Settings** — pydantic-settings or Django settings module for model ids and keys.
- **Tests** — VCR or mock transport; no live API in default test suite.
