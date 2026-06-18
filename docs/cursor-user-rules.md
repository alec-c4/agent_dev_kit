# Cursor user rules integration

Agent Dev Kit and your global Cursor rules (`~/.cursor/rules/*.mdc`) can overlap — for example TDD, semantic commits, and git branching. Loading both wastes tokens and can confuse the agent.

**Policy:** user rules always win. The kit **skips reading duplicate guideline files** when a matching user rule is present.

## How it works

```
~/.cursor/rules/tdd.mdc          (alwaysApply — Cursor injects)
~/.cursor/rules/semantic-commits.mdc
        ↓ matched by registry/cursor-user-rules.yaml
~/.cursor/kit-user-rules.manifest.json   (generated)
        ↓ agent reads manifest
skip: docs/guidelines/TESTING.md, COMMITS.md, …
always load: SPECS.md, WORKFLOW.md, VERIFICATION.md, REVIEW.md
```

| Layer | Role |
|-------|------|
| User `*.mdc` | Authoritative for covered topics (TDD, commits, git, code style) |
| `kit-user-rules.mdc` | Tells the agent to read the manifest and skip duplicates |
| `kit-*.mdc` (other) | Workflow routing, stack detection — on demand |
| `docs/guidelines/` | Kit-only workflow (spec, verification) + uncopied topics |

## Setup

Run once after install or when you add/rename user rules:

```text
./scripts/kit sync-rules
```

`./scripts/kit install --target=cursor` runs this automatically.

Output: `~/.cursor/kit-user-rules.manifest.json` (machine-local, not committed).

## Default topic map

| User rule pattern | Kit guidelines skipped |
|-------------------|------------------------|
| `tdd.mdc` | `TESTING.md` |
| `semantic-commits.mdc` | `COMMITS.md` |
| `git-branching-flow.mdc` | `GIT.md` |
| `*-code-style.mdc`, `coding.mdc` | `CODING.md` |

Always loaded (kit-only): `SPECS.md`, `WORKFLOW.md`, `VERIFICATION.md`, `REVIEW.md`.

Edit `registry/cursor-user-rules.yaml` to add patterns, then:

```text
./scripts/kit compile
./scripts/kit sync-rules
```

## Local overrides

Create `~/.cursor/kit-user-rules.local.yaml` (not in git) for personal rules:

```yaml
extra_topics:
  inertia_i18n:
    user_rule_patterns:
      - "^inertia-i18n\\.mdc$"
    skip_kit_guidelines: []

additional_skip:
  - docs/guidelines/CODING.md
```

Re-run sync after edits.

## Project-level rules

If the target app has `.cursor/rules/` (non-kit), include them in the scan:

```bash
bash scripts/sync-cursor-user-rules.sh \
  --rules-dir ~/.cursor/rules \
  --rules-dir .cursor/rules
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Agent re-reads TESTING.md despite `tdd.mdc` | Run sync; restart Cursor; confirm `kit-user-rules.mdc` is installed |
| Wrong file skipped | Adjust patterns in `cursor-user-rules.yaml` or local overlay |
| Manifest missing | `./scripts/kit sync-rules` |

## Claude Code and other tools

This dedup path is **Cursor-specific** (`.mdc` rules + manifest). Claude Code uses `~/.claude/CLAUDE.md` → `AGENTS.md`; defer language in guidelines still applies — agents should not re-load topics already in user instructions.
