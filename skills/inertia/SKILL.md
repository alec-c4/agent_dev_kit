---
name: inertia
description: Inertia.js patterns with Rails or Node backends. Load when inertia_rails or @inertiajs present per stack profile.
user-invokable: false
---

# Inertia.js patterns

Load when Inertia gem/package detected ([stacks/rails](../stacks/rails/profile.yaml) or Node stack).

## Server

- Return `Inertia.render` with props — no duplicate REST API for same page data unless needed for mobile/API clients.
- Shared data via `inertia_share`; flash via session.

## Client

- Page components colocated with framework (React/Vue/Svelte) per project layout.
- Preserve `preserveState` / `preserveScroll` intentionally on pagination filters.

## Testing

- Request specs assert Inertia component name and key props — avoid snapshotting entire JSON blobs.
