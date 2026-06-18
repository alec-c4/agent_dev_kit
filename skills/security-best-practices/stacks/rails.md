# Rails security

- **Strong params** and explicit authorization (Pundit/CanCan) on every mutating action.
- **CSRF** on session forms; **Content-Security-Policy** when the app serves HTML.
- **SQL** — bind parameters; avoid `send`/`constantize` on user input.
- **Mass assignment** — `params.expect` / permitted attributes only.
- **Sessions** — secure cookies in production; rotate secrets; short TTL for sensitive apps.
- Run Brakeman from stack `profile.yaml` `tooling.security` when configured.
