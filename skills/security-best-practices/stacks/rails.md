# Rails security

- **Strong params** and explicit authorization (Pundit or CanCanCan) on every mutating action.
- **Roles** via role_fu (or rolify in existing projects) — a role check is membership, never
  a replacement for the policy check on the action.
- **CSRF** on session forms; **Content-Security-Policy** when the app serves HTML.
- **SQL** — bind parameters; avoid `send`/`constantize` on user input.
- **Mass assignment** — permitted attributes only. Rails 8 adds `params.expect(user: [:name])`,
  which requires and permits in one call and returns 400 on the wrong shape; on Rails 7 use
  `params.require(:user).permit(...)`. Never `expect`/`permit` with a bare `{}`.
- **Sessions** — secure cookies in production; rotate secrets; short TTL for sensitive apps.
- Run Brakeman from stack `profile.yaml` `tooling.security` when configured.
