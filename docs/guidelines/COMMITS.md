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

## Review before commit (optional gate)

When review hooks are installed (Phase 3), every commit requires an explicit developer approval after review. See [REVIEW.md](REVIEW.md).
