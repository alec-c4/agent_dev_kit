# Shell and kit commands

Agent Dev Kit scripts are **bash**. Your **interactive shell** (fish, zsh, bash, …) can differ. Use the kit CLI so commands work the same everywhere.

## Rule

| Context | What to use |
|---------|-------------|
| Kit install, validate, detect-stack, compile | `./scripts/kit …` |
| Ad-hoc terminal commands (git, npm, …) | **Your** `$SHELL` syntax |
| AI suggests copy-paste commands | Match the developer's shell — see user rule `fish-shell.mdc` if present |

Kit docs use `./scripts/kit` — not fish-only or bash-only chains for kit maintenance.

## Kit CLI

From the kit repo root (works in fish, zsh, bash):

```text
./scripts/kit install --target=all
./scripts/kit install --target=both --with-hooks --with-review-gate
./scripts/kit compile
./scripts/kit validate --phase=1
./scripts/kit validate-skills --pack=core
./scripts/kit deploy-skills --pack=core --scope=project --dry-run
./scripts/kit deploy-workflows --scope=project --dry-run
./scripts/kit intake GH-58 --paste --dry-run <<'EOF'
Ticket title and body
EOF
./scripts/kit sync-tracker --dry-run
./scripts/kit validate-handoff GH-58 --file=docs/examples/work/GH-58-handoff.example.md
./scripts/kit detect-stack --write-profile
./scripts/kit sync-rules
./scripts/kit shell-info
./scripts/kit run install.sh --dry-run --target=cursor
```

The wrapper always invokes bash for kit scripts. Your `$SHELL` is irrelevant for these.

## Detect your interactive shell

```text
./scripts/kit shell-info
./scripts/kit shell-info --json
```

Example JSON:

```json
{
  "interactive_shell": "fish",
  "interactive_shell_path": "/opt/homebrew/bin/fish",
  "kit_script_runner": "bash",
  "command_chain_hint": "fish: use '; and' between commands (not &&)"
}
```

Agents: run `shell-info` when suggesting **interactive** command chains. Use `./scripts/kit` for kit scripts regardless.

## Command chaining (interactive only)

| Shell | Chain two commands |
|-------|-------------------|
| bash / zsh | `cmd1 && cmd2` |
| fish | `cmd1; and cmd2` |

Do not assume fish or bash in kit guidelines. [WORKFLOW.md](guidelines/WORKFLOW.md) git examples use single commands or portable blocks.

## User Cursor rules

If the developer has `fish-shell.mdc` (or another shell rule), **that rule wins** for commands you ask them to run manually. Kit does not duplicate shell syntax in guidelines.

## Agent / CI

- **Cursor agent shell tool** may run bash or zsh — either is fine for kit scripts via `./scripts/kit`.
- **CI** should call `./scripts/kit validate` or `bash scripts/validate-registry.sh` explicitly.

## Legacy

`bash scripts/install.sh` still works. Prefer `./scripts/kit install` in new docs.
