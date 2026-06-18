# Git workflow

Kit-specific git practices. Branch strategy defaults defer to the developer's global rules when present (for example Cursor `git-branching-flow.mdc`).

## Detect flow before branching

| Signal | Flow |
|--------|------|
| `develop` branch exists | Git Flow |
| `CLAUDE.md` or `README.md` sets `git_flow: true` | Git Flow |
| `main` or `master` only | **GitHub Flow** (default) |

When unsure, use **GitHub Flow**.

## GitHub Flow (default)

1. Branch from default: `feature/<short-name>`, `fix/<short-name>`, `docs/<short-name>`.
2. One atomic commit per logical change.
3. Rebase onto default before merge: `git rebase master` (or `main`).
4. Review → merge with `--ff-only`.
5. Delete the branch after merge.

## Git Flow

1. Feature branches from `develop`.
2. Same atomic commit discipline.
3. Rebase onto `develop` before merge.
4. Release: `release/x.y.z` from `develop`.
5. Hotfix: from `master`, merge to `master` and `develop`.

## Merge policy

- Goal: **linear history**.
- Rebase before merge; avoid unnecessary merge commits.
- Prefer `--ff-only`; investigate if fast-forward fails.
- Delete merged branches promptly.

## Staging discipline

Before every commit:

```bash
git diff --staged --stat
```

If staged changes span multiple features:

1. `git restore --staged .`
2. Stash unrelated work: `git stash push -m "wip: …" -- <files>`
3. Stage one feature: `git add -p`
4. Commit, then repeat.

## Protected branches

Never commit or push directly to `main`, `master`, or `develop`. Use feature branches and PRs.

## Review gate (optional, Phase 3)

When hooks are installed with `--with-review-gate`, commits require a passing review flag. See [REVIEW.md](REVIEW.md).
