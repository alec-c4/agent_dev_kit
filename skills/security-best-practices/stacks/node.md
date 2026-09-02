# Node / JS security

- **Input validation** — Zod/Joi at API boundaries; never trust client-only checks.
- **Auth** — httpOnly cookies or short-lived JWT; verify issuer/audience; no secrets in frontend bundles.
- **Headers** — helmet or equivalent (CSP, HSTS, X-Frame-Options).
- **Dependencies** — `npm audit` / `pnpm audit`; pin critical security patches.
- **SSRF** — resolve and reject private and link-local ranges before fetching a user-supplied URL; re-check after redirects.
- Run stack `profile.yaml` lint/security scripts when present.
