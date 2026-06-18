---
name: docker-patterns
description: Docker and container patterns — images, compose, multi-stage builds, CI. Load for containerized apps and deploy pipelines.
user-invokable: false
---

# Docker patterns

Use when authoring Dockerfiles, Compose files, or container CI steps.

## Images

- **Multi-stage builds** — separate build and runtime; minimal final image (distroless or slim base when possible).
- **Layer order** — dependency install before app copy; leverage build cache.
- **Non-root user** — run as unprivileged UID in production images.
- **`.dockerignore`** — exclude `.git`, `node_modules`, `.env`, local artifacts.

## Compose

- Pin image digests or minor tags in production compose; document dev overrides in `compose.override.yaml`.
- Healthchecks on services the app depends on; explicit `depends_on` with condition when supported.
- Secrets via env files **not** committed — use `.env.example` only.

## CI

- Build and scan in CI (`docker scout`, Trivy, or registry scanner) before push.
- Tag with git SHA; avoid `latest` only in production registries.

## Do not

- Bake secrets or `.env` into images.
- Run as root in production without justification.

## References

- [Docker docs](https://docs.docker.com/)
