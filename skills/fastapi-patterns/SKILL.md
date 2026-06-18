---
name: fastapi-patterns
description: FastAPI patterns — routers, dependency injection, Pydantic v2. Load after stacks/fastapi profile.
user-invokable: false
---

# FastAPI patterns

Load after [stacks/fastapi](../stacks/fastapi/SKILL.md).

## Structure

- **APIRouter** per domain; mount in `main.py`.
- **Depends** for DB sessions, auth, settings — no global mutable state.
- **Pydantic v2** models for request/response ([profile dod_overlay](../stacks/fastapi/profile.yaml) `pydantic_validation`).

## Async

- Use `async def` only when IO-bound; avoid blocking calls in async routes.

## Testing

- `TestClient` / `httpx.AsyncClient` with dependency overrides for DB.

## References

- [FastAPI docs](https://fastapi.tiangolo.com/)
