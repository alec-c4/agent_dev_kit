# Elixir / Phoenix security

- **Contexts** — business rules in contexts; controllers thin; authorize in context or policy modules.
- **Ecto** — `Repo.get_by!` with scoped queries; never interpolate into fragments.
- **LiveView** — validate assigns server-side; CSRF on forms; rate-limit sensitive events.
- **Secrets** — `Application.get_env` / runtime config; use `mix phx.gen.secret` for signing salts.
- **Dependencies** — `mix deps.audit` when available.
