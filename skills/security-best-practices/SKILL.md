---
name: security-best-practices
description: Cross-stack security checklist and stack-specific hardening. Load from detect-stack topic_files or review step 0.
user-invokable: false
---

# Security best practices

Apply **universal checks** first, then the stack file from `topic_files.security` in the detect-stack profile.

## Universal (all stacks)

From [REVIEW.md](../../docs/guidelines/REVIEW.md) step 0:

1. **State transitions** — invalid lifecycle states blocked?
2. **Data isolation** — no cross-tenant or cross-user leakage?
3. **External failures** — timeouts, retries, safe defaults on dependency errors?
4. **Untested edge cases** — nil, empty, unauthorized, boundary inputs covered?

Also:

- Validate and sanitize all external input at trust boundaries.
- Secrets only via env/credentials — never commit or log.
- Run stack `tooling.security` commands from `profile.yaml` when present.

## Stack reference

| Stack family | File |
|--------------|------|
| Rails | [stacks/rails.md](stacks/rails.md) |
| Node / Next / Nuxt / Svelte | [stacks/node.md](stacks/node.md) |
| Python / Django / FastAPI / Flask | [stacks/python.md](stacks/python.md) |
| Elixir / Phoenix | [stacks/elixir.md](stacks/elixir.md) |
| Go | [stacks/go.md](stacks/go.md) |

Load the file matching the detected primary stack.
