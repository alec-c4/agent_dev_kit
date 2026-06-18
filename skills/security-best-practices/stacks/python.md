# Python security

- **Validation** — Pydantic models for APIs; Django forms/serializers for web.
- **ORM** — parameterized queries; never format SQL with user strings.
- **Secrets** — `django.conf.settings` / env; no keys in notebooks or tests committed to git.
- **File uploads** — content-type and size limits; store outside web root.
- **CSRF** — enabled for session-backed Django/Flask forms.
- Run bandit/ruff security rules from stack profile when configured.
