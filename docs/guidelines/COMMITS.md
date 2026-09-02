# Commit guidelines

## Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]
```

- **description:** imperative mood, lowercase, no trailing period, ~72 characters.
- **body:** explain what changed and why — not how.

### Types

| Type | Use when |
|------|----------|
| `feat` | New user-visible behaviour |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `test` | Tests only |
| `refactor` | Code change, not feat/fix |
| `chore` | Maintenance, tooling |
| `ci` | CI/CD config |

## Scope discipline

- One logical change per commit.
- Litmus test: describe the commit in one imperative sentence **without** the word "and". If you cannot, split it.
- Before commit: `git diff --staged --stat`.

## Branch policy

See [GIT.md](GIT.md). Never commit directly to `main`, `master`, or `develop`.

## User rules override

When the developer uses semantic commit rules (for example Cursor `semantic-commits.mdc`), **follow those**. This file aligns with them; it does not weaken them.

## No AI attribution

Do not add agent attribution to commits or PRs:

- No `Co-authored-by: Cursor` / `Co-authored-by: Claude` trailers.
- No "Generated with …" lines in messages or PR bodies.

Disable automatic attribution in Cursor and Claude Code: [tool-settings.md](../tool-settings.md) or `./scripts/kit configure --init-config`.

## Shipped language

Default `.ai/kit.yaml` → `process_references: omit`.

Commit subjects and bodies (and PR titles/bodies) are for **repository readers**, not the internal plan:

- Do not cite implementation plans, stages/phases, handoff files, or `.ai/work/*` paths.
- Prefer what shipped over which plan step completed it.
- Opt out with `process_references: allow` when the project explicitly wants that jargon.

See [AGENTS.md](../../AGENTS.md#shipped-language) and [CODING.md](CODING.md#shipped-language).

## Review before commit (optional gate)

When review hooks are installed, every commit requires an explicit developer approval after review. See [REVIEW.md](REVIEW.md).
