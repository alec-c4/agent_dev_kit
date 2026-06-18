# Elixir RAG

- **Oban** — ingest and embed jobs with uniqueness constraints.
- **Ecto** — chunk table with `embedding_model`, `source_id`, tenant fields.
- **pgvector** — native when on Postgres; otherwise HTTP to vector service.
- **LiveView** — show citations from retrieved chunk ids; no raw index dumps to client.
- **Tests** — ExUnit with sandbox DB and stubbed embed API.
