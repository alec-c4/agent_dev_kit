---
name: rails-api
description: Rails API-only patterns — JSON endpoints, serializers, auth, no HTML views. Load when config.api_only is set.
user-invokable: false
---

# Rails API-only

Load when `config.api_only = true` in `config/application.rb` ([stacks/rails](../stacks/rails/profile.yaml) `if_file`).

## Structure

- **Controllers** return JSON only — no implicit HTML templates or view helpers.
- **Serializers** or explicit `render json:` shapes — one response contract per endpoint; version public APIs when breaking fields.
- **Namespaces** — `Api::V1::` (compact syntax) for versioned public APIs.

## Auth and CORS

- Token/session strategy documented per project (Devise API, JWT, OAuth2 bearer).
- **CORS** configured in `config/initializers/cors.rb` for browser clients — not wide open in production.
- Rate limiting and auth on every mutating route — no «internal» skips without network isolation.

## Testing

- Request specs assert status, JSON schema/keys, and auth failures — not HTML bodies.
- Contract tests for mobile/SPA consumers when multiple clients share the API.

## Not applicable

- Importmap, Hotwire page skills, and Inertia — skip unless the repo also contains a separate frontend app (detect that stack independently).

## References

- [Rails API mode](https://guides.rubyonrails.org/api_app.html)
