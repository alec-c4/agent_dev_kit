---
name: llm-integration
description: Patterns for calling LLM APIs, streaming, structured output, and cost controls per stack.
user-invokable: false
---

# LLM integration

Use when adding chat, completion, embeddings, or agent features. Read the stack file from `topic_files.llm` after [stack-detection](../stack-detection/SKILL.md).

## Universal principles

- **Provider abstraction** — isolate vendor SDK behind one module; swap models via config.
- **Secrets** — API keys in env only; never in client bundles or logs.
- **Timeouts and retries** — bounded retries with backoff; fail closed on auth errors.
- **Structured output** — schema-validate JSON; do not trust free-form parsing for control flow.
- **Cost** — cap tokens, log usage in server paths, cache idempotent reads where safe.

## Stack reference

| Stack family | File |
|--------------|------|
| Rails | [stacks/rails.md](stacks/rails.md) |
| Node / Next / Nuxt / Svelte | [stacks/node.md](stacks/node.md) |
| Python / Django / FastAPI | [stacks/python.md](stacks/python.md) |
| Elixir / Phoenix | [stacks/elixir.md](stacks/elixir.md) |

Follow project conventions for AI SDK (Vercel AI SDK, LangChain, etc.) when already present — do not add a second stack.
