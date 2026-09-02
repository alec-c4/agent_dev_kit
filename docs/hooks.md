# Hooks reference

Shared shell hooks for **Claude Code** and **Cursor**. Same scripts, different JSON adapters.

## Install

```bash
# With full kit install (Claude + Cursor targets)
./scripts/kit install --target=both --with-hooks

# Opt-in review gate (blocks git commit without review-passed flag)
./scripts/kit install --target=both --with-hooks --with-review-gate

# Hooks only
./scripts/kit deploy-hooks --scope=global --target=both
./scripts/kit deploy-hooks --scope=project --target=both --review-gate
```

Claude: merge `settings.hooks.kit.json` into `~/.claude/settings.json`, or use `--merge-settings` when `jq` is available.

Cursor: writes `~/.cursor/hooks.json` (global) or `./.cursor/hooks.json` (project). Restart the IDE after install.

Deny text is always three lines so models can act on it:

```text
Blocked: <what>
Why: <reason>
Next: <what to do>
```

Each line is specific to the blocked command — `Why` explains the risk, `Next` gives a command or step the agent can actually take. `scripts/validate-registry.sh` fails if a hook falls back to the generic wording.

**Dependencies:** deny hooks parse the tool payload with `jq` (preferred) or `python3`. With neither on `PATH` they deny and say so rather than allowing the command through. `auto-format.sh` is fail-open by design — a missing formatter is not a safety problem.

## Hook scripts

| Script | When | Policy |
|--------|------|--------|
| `block-dangerous.sh` | Before shell | Fail-closed — rm -rf, force push, hard reset, DROP/TRUNCATE |
| `protect-secrets.sh` | Before shell | Fail-closed — .env, keys, inline Bearer tokens |
| `check-branch-protection.sh` | git commit/push | Fail-closed — blocks main, master, develop |
| `check-commit-scope.sh` | git commit | Fail-closed — broad staged area, «and» in message |
| `enforce-review-before-commit.sh` | git commit | Opt-in — requires review-passed flag |
| `clear-review-flag.sh` | After git commit | Fail-open — clears one-use review flags |
| `auto-format.sh` | After file edit | Fail-open — standardrb, eslint, ruff, gofmt when present |
| `warm-stack-profile.sh` | Session start | Fail-open — `./scripts/kit detect-stack --write-profile` |
| `mark-review-passed.sh` | Manual / after /review | Sets `.claude/.cursor/.agents/review-passed` |

Cursor wrappers live in `hooks/cursor/` (JSON deny responses). Claude uses `hooks/*.sh` directly (exit 2).

## Review gate (opt-in)

Enable with `--with-review-gate` or create `.ai/kit-review-gate` in the project.

After human approves review:

```bash
bash hooks/mark-review-passed.sh
# or
bash hooks/mark-review-passed.sh --target=cursor
```

Flags are **one-use** — cleared after the next successful `git commit`.

## Antigravity and Codex

- **Antigravity** — reuse the same shell scripts when hook API supports git/shell events; no template shipped yet.
- **Codex** — no hook JSON; use sandbox and approval settings documented in [tool-adapters.md](tool-adapters.md).

## Troubleshooting

- Hooks need **jq** or **python3** to parse stdin JSON.
- Cursor: check **Hooks** output channel; paths in `hooks.json` must be absolute for global install.
- Claude: confirm `settings.json` includes the `hooks` block from `settings.hooks.kit.json`.

See [REVIEW.md](guidelines/REVIEW.md) and [GIT.md](guidelines/GIT.md).
