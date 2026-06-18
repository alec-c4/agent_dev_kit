# Rails RAG

- **Ingest** — ActiveStorage + background job; text extract via existing gems (pdf-reader, etc.).
- **Embed** — batch in Sidekiq/Solid Queue; store vectors in pgvector or external index with ACL metadata.
- **Query** — scope retrieval by `Current.user` / tenant id before passing context to LLM.
- **ActiveRecord** — separate `DocumentChunk` model; version embedding model on rows.
- **Eval** — rake task or minitest/rspec examples with frozen golden set.
