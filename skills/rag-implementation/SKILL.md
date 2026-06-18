---
name: rag-implementation
description: Retrieval-augmented generation — chunking, embeddings, vector store, and evaluation per stack.
user-invokable: false
---

# RAG implementation

Use when building search-over-documents or knowledge-grounded answers. Read `topic_files.rag` from detect-stack output.

## Universal pipeline

1. **Ingest** — normalize formats; preserve metadata (source, version, ACL).
2. **Chunk** — size/overlap tuned to content; keep headings with chunks when possible.
3. **Embed** — batch embed; store model id with vectors for re-index migrations.
4. **Retrieve** — hybrid search (keyword + vector) when scale requires it; filter by ACL before LLM.
5. **Generate** — cite sources; refuse when retrieval confidence is low.
6. **Evaluate** — golden questions + regression set; track hit rate and hallucination flags.

## Stack reference

| Stack family | File |
|--------------|------|
| Rails | [stacks/rails.md](stacks/rails.md) |
| Node / Next / Nuxt / Svelte | [stacks/node.md](stacks/node.md) |
| Python / FastAPI | [stacks/python.md](stacks/python.md) |
| Elixir / Phoenix | [stacks/elixir.md](stacks/elixir.md) |

Prefer existing vector DB and job infrastructure in the project before adding new services.
