# Tool adapters

Agent Dev Kit uses **one canonical entry** — [AGENTS.md](../AGENTS.md) — and thin per-tool adapters. Guidelines in `docs/guidelines/` are never duplicated inside adapters.

Install map (machine-readable): [registry/tool-targets.yaml](../registry/tool-targets.yaml).

## Tool matrix

Table 1: entry points and install targets.

| Tool | Canonical | Adapter | Install |
|------|-----------|---------|---------|
| Any | `AGENTS.md` | — | copy or symlink into project root |
| Cursor | `AGENTS.md` | `templates/cursor/rules/kit-*.mdc` | `./scripts/kit install --target=cursor` |
| Claude Code | `AGENTS.md` | [CLAUDE.md](../CLAUDE.md) | `./scripts/kit install --target=claude` |
| OpenAI Codex CLI | `AGENTS.md` | — (native) | `./scripts/kit install --target=codex` |
| Google Antigravity | `AGENTS.md` | [GEMINI.md](../GEMINI.md) | `./scripts/kit install --target=antigravity` |
| Copilot | `AGENTS.md` | `.github/instructions/` (not shipped) | project `AGENTS.md` |
| Windsurf | `AGENTS.md` | — | project `AGENTS.md` |

Install all supported targets:

```bash
./scripts/kit install --target=all
```

Outer sensors: Claude Code and Cursor install kit hooks. Codex uses the host sandbox plus `./scripts/kit check-patterns` at verify. Antigravity hook wiring is not shipped.

Legacy alias `--target=both` installs Claude Code + Cursor only.

## AGENTS.md merge order

Each tool loads `AGENTS.md` differently. Keep **universal rules in AGENTS.md** and **tool-specific overrides** in `CLAUDE.md` or `GEMINI.md`.

### Codex CLI

Source: [Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md).

1. Global: `$CODEX_HOME/AGENTS.override.md` if present, else `$CODEX_HOME/AGENTS.md` (default `$CODEX_HOME` is `~/.codex`).
2. Project: walk from git root to current directory; at each level, `AGENTS.override.md` or `AGENTS.md`.
3. Concatenate root → CWD (deeper files appear later and override earlier text).
4. Combined size capped by `project_doc_max_bytes` in `config.toml` (32 KiB default).

**Debug:** run `codex --print-instructions` to dump merged content for the current session.

**Size tip:** keep global `AGENTS.md` thin; reference `docs/guidelines/` by path. Use `--project` install so guideline files exist beside the project `AGENTS.md`.

### Antigravity

Source: [AGENTS.md guide for Antigravity](https://antigravity.codes/blog/antigravity-agents-md-guide).

1. System rules (immutable).
2. `GEMINI.md` — Antigravity-specific; **wins over AGENTS.md** on conflict.
3. `AGENTS.md` — shared with Cursor, Codex, Claude Code.
4. `.agent/rules/` supplements (optional).

Global files: `~/.gemini/AGENTS.md`, `~/.gemini/GEMINI.md`. Project: repo root `AGENTS.md` and optional `GEMINI.md`.

### Cursor and Claude Code

- **Global install** (`./scripts/kit install --target=cursor`) — `~/.cursor/rules/kit-*.mdc` apply in **every project**, but only in the **Cursor IDE**. The standalone Cursor CLI (`agent`/`cursor-agent` binary) does not read `~/.cursor/rules/`; it only loads project `AGENTS.md` and project `.cursor/rules/*.mdc` — see [cursor-user-rules.md#cursor-cli-vs-cursor-ide](cursor-user-rules.md#cursor-cli-vs-cursor-ide).
- **Project install** (`--project`, e.g. `./scripts/kit install --target=cursor --project`) — shared `AGENTS.md`, `.agents/skills/`, project `.cursor/rules/` for the team; required for the Cursor CLI to see kit workflow/comprehension rules. Do not overwrite an existing project `docs/` tree.
- Cursor: `AGENTS.md` + optional `kit-*.mdc` rules; user `~/.cursor/rules/` win when stricter.
- Tool settings: `~/.config/agent_dev_kit/config.yaml` — see [tool-settings.md](tool-settings.md) (permissions, attribution).
- Claude Code: `CLAUDE.md` adapter + `AGENTS.md`; slash commands come from the skill directories.

## Skills and workflows

Table 2: where kit skills and shortcuts deploy.

| Tool | Global skills | Project skills | Shortcuts |
|------|---------------|----------------|-----------|
| Codex | `~/.agents/skills/` | `.agents/skills/` | `$skill-name`, `/skills` |
| Antigravity IDE | `~/.gemini/config/skills/` | `.agents/skills/` | `.agents/workflows/*.md` |
| Antigravity CLI | `~/.gemini/antigravity-cli/skills/` | `.agents/skills/` | same as IDE when synced |
| Claude Code | `~/.claude/skills/` | `.claude/skills/` | `/feature`, `/fix`, … |
| Cursor | user skills dir | project skills | rules, `@` mentions |

**CLI quirk:** Antigravity CLI may not read `~/.agents/skills/`. Copy or symlink kit skills to `~/.gemini/antigravity-cli/skills/` if CLI sessions miss them. Documented in install output.

`deploy-skills` installs kit skills to `.agents/skills/`; workflow shortcuts are per tool:

| Tool | Skills (`deploy-skills`) | Shortcuts (`deploy-workflows`) |
|------|--------------------------|--------------------------------|
| Codex | `$feature`, `$fix`, … in `.agents/skills/` | — |
| Claude Code | `~/.claude/skills/` | `/feature`, … from the skill directory names |
| Antigravity | `.agents/skills/` | `.agents/workflows/*.md` |

See [commands/README.md](../commands/README.md) and [INTENT-ROUTING.md](guidelines/INTENT-ROUTING.md).

## Project scaffold (`.agents/`)

`./scripts/kit install --target=codex|antigravity|all --project` creates:

```
.agents/
  skills/       # SKILL.md packages
  workflows/    # Antigravity slash workflows
```

`.ai/` holds specs and plans — see [TRACKER.md](guidelines/TRACKER.md).

## Install behaviour

| Flag | Effect |
|------|--------|
| `--target=codex` | Deploy to `$CODEX_HOME` (default `~/.codex`) |
| `--target=antigravity` | Deploy to `~/.gemini/` |
| `--target=all` | claude + cursor + codex + antigravity |
| `--project` | Current repo: root `AGENTS.md`, `.agents/` scaffold, tool-specific dirs |
| `--copy` | Copy files instead of symlinks |
| `--force` | Replace existing `GEMINI.md` or `AGENTS.override.md` |
| `--dry-run` | Print actions only |

Install **does not** overwrite an existing user `AGENTS.override.md` or `GEMINI.md` unless `--force`.

## Intent routing by tool

Plain text and explicit shortcuts share one pipeline — [INTENT-ROUTING.md](guidelines/INTENT-ROUTING.md).

| Tool | Explicit shortcut | Plain text |
|------|----------------------------|------------|
| Claude Code | `/feature`, `/fix` | classify in AGENTS.md Step 0 |
| Codex | `$feature` skill | `$intent-router` or AGENTS.md |
| Antigravity | workflow slash | GEMINI.md + AGENTS.md |
| Cursor | `@kit-workflow` rule | AGENTS.md + skills |

## Codex sandbox and approvals

Codex has no Cursor-style hook JSON. Use `config.toml` sandbox tiers and `--ask-for-approval` for dangerous commands. Kit documents gates in [WORKFLOW.md](guidelines/WORKFLOW.md) and defers to user `request-validation` rules.

## References

- [Codex AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
- [Codex skills](https://developers.openai.com/codex/skills)
- [Antigravity AGENTS.md guide](https://antigravity.codes/blog/antigravity-agents-md-guide)
- [Antigravity skills codelab](https://codelabs.developers.google.com/getting-started-with-antigravity-skills)
