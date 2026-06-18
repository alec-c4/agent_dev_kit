---
name: go-service-patterns
description: Go service patterns — packages, context, errors, HTTP handlers. Load after stacks/go profile.
user-invokable: false
---

# Go service patterns

Load after [stacks/go](../stacks/go/SKILL.md).

## Structure

- **Small packages** by domain; `internal/` for private code.
- **context.Context** on all IO paths with timeouts ([profile dod_overlay](../stacks/go/profile.yaml) `context_timeouts`).
- Wrap errors with `%w`; return errors, do not panic in libraries.

## HTTP

- Standard library `net/http` or chi/echo per project — one router style per repo.
- Middleware for logging, auth, recovery.

## Testing

- Table-driven tests; `go test ./...` from profile.

## References

- [Effective Go](https://go.dev/doc/effective_go)
