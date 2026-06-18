# Go security

- **Context** — pass `context.Context` with deadlines on all IO.
- **SQL** — `database/sql` placeholders or sqlc; no string concatenation.
- **HTTP** — limit body size; validate paths; use `http.MaxBytesReader`.
- **Crypto** — `crypto/rand` for tokens; compare secrets with `subtle.ConstantTimeCompare`.
- **Modules** — `govulncheck` in CI when stack profile enables it.
