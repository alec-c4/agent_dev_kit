# Node RAG

- **Ingest** — upload API + queue worker (BullMQ, Inngest, etc.).
- **Vector store** — Pinecone, pgvector, or Turbopuffer — match what the repo already uses.
- **Chunking** — langchain/text splitters or custom; preserve source URLs for citations.
- **API routes** — retrieve server-side; stream answer with cited chunk ids.
- **Eval** — Vitest fixtures with mocked embedder + retriever scores.
