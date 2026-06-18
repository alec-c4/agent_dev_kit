# Python RAG

- **FastAPI/Django** — async ingest pipeline; Celery/RQ for heavy parsing.
- **Libraries** — LlamaIndex/LangChain only if present; otherwise thin wrapper over provider embed API.
- **Storage** — SQLAlchemy/Django ORM + pgvector or dedicated vector service.
- **ACL** — filter metadata in retrieval query, not post-hoc in prompt only.
- **Eval** — pytest with snapshot expected citations.
