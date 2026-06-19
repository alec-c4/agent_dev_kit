# Tool settings

Kit syncs recommended Cursor and Claude Code settings from one XDG config file.

## Config location

```text
~/.config/agent_dev_kit/config.yaml
```

Template: [templates/config/config.yaml.example](../templates/config/config.yaml.example).

Kit defaults (permissions, attribution): [registry/tool-settings.yaml](../registry/tool-settings.yaml).

## What `kit configure` does

1. Loads kit defaults from `registry/tool-settings.json`
2. Merges your `config.yaml` overrides
3. **Union-merges** into existing tool configs (does not remove your current allow rules):

| Tool | Target file |
|------|-------------|
| Cursor | `~/.cursor/cli-config.json` |
| Claude Code | `~/.claude/settings.json` |

Merged fields today:

- `permissions.allow` / `permissions.deny` (and Claude `permissions.ask`)
- `attribution` (no AI attribution by default — see [COMMITS.md](guidelines/COMMITS.md))
- Claude: `includeGitInstructions`

Your existing entries stay; kit adds missing recommended rules.

## Example config

```yaml
attribution:
  commits: false
  prs: false

cursor:
  permissions:
    allow:
      - Shell(gh)
      - Mcp(plugin-svelte-svelte:list-sections)

claude:
  permissions:
    allow:
      - Bash(gh *)
      - Bash(mise *)
  includeGitInstructions: true
```

Permission syntax differs between tools:

- **Cursor:** `Shell(git status)`, `Mcp(server, tool)`
- **Claude Code:** `Bash(git *)`, `Read(./path)`

## Commands

Apply kit defaults + your config to both tools:

```text
./scripts/kit configure
```

First-time setup (creates `config.yaml` from template if missing):

```text
./scripts/kit configure --init-config
```

Per tool:

```text
./scripts/kit configure --target=cursor
./scripts/kit configure --target=claude
```

Disable attribution only:

```text
./scripts/kit configure --disable-attribution --init-config
```

Preview JSON output:

```text
./scripts/kit configure --dry-run --target=both
```

## Install

Cursor or Claude install runs configure automatically:

```text
./scripts/kit install --target=both
./scripts/kit install --target=claude --disable-attribution
```

`--disable-attribution` also initializes `config.yaml` when absent.

Restart Cursor or start a new Claude Code session after changes.

## Related

| Doc | Topic |
|-----|-------|
| [COMMITS.md](guidelines/COMMITS.md) | No attribution policy |
| [hooks.md](hooks.md) | Shell hooks (separate from permissions) |
| [tool-adapters.md](tool-adapters.md) | Install paths |
