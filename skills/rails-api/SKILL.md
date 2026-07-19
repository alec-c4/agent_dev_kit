---
name: rails-api
description: Rails API-only patterns — JSON endpoints, serializers, auth, no HTML views. Load when config.api_only is set.
user-invokable: false
---

# Rails API-only

Load when `config.api_only = true` in `config/application.rb` ([stacks/rails](../stacks/rails/profile.yaml) `if_file`).

## Application layout

- **No** `ApplicationController` view helpers by default — middleware stack omits session/cookies unless explicitly added.
- **Controllers** under `app/controllers/api/v1/` (compact syntax: `class Api::V1::UsersController`).
- **Single responsibility** per action — index/show/create/update/destroy; avoid RPC-style `do_everything` endpoints.
- **Versioning:** URL prefix (`/api/v1/`) or header — pick one per project; document breaking changes.

## JSON responses

- **Serializers** (project choice: Alba, Blueprinter, JSON:API serializer, Jbuilder) — one schema per public resource.
- **Explicit shapes** — `render json: UserSerializer.new(user)`; avoid leaking all model columns via `as_json` without review.
- **Pagination:** cursor or offset — consistent meta (`meta.page`, `links.next`) across index actions.
- **Errors:** structured body, e.g. `{ errors: [{ field, message }] }` with appropriate HTTP status (422 validation, 404 not found, 403 forbidden).

## Auth

- Strategy per project: **Devise** (token/session API), **JWT** (short-lived access + refresh), **OAuth2** bearer (Doorkeeper or provider).
- Authenticate **before** action logic — `before_action :authenticate_user!` or equivalent.
- **Scopes/roles** checked at resource level — not only «logged in».

## CORS and headers

- **`rack-cors`** in `config/initializers/cors.rb` — whitelist origins in production; no `origins '*'` with credentials.
- **Security headers** via `secure_headers` or Rails defaults — document API-specific CSP if any HTML error pages exist.

## Rate limiting and abuse

- **rack-attack** or gateway-level limits on auth and write endpoints when project uses them.
- Idempotency keys for payment-like POST when documented in spec.

## Background work

- Long IO (email, webhooks, exports) via **Active Job** — return `202 Accepted` + job id when async pattern is used.

## Testing

- **Request specs** (RSpec) or integration tests (Minitest) — assert status, JSON keys, auth failures.
- No HTML assertions; no Hotwire/Inertia skills unless monorepo adds separate frontend repo.
- Contract tests when mobile/SPA clients share the API.

## Not applicable

- Importmap, Hotwire, Inertia — skip for API-only Rails; detect frontend stack in sibling app if monorepo.

## References

- [Rails API applications](https://guides.rubyonrails.org/api_app.html)
- [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html)
