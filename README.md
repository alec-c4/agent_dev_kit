# Agent Dev Kit

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Universal developer kit for AI-assisted product engineering. **LLM-agnostic** and **stack-agnostic** — works with Cursor, Claude Code, OpenAI Codex, Google Antigravity, Copilot, Windsurf, and others.

## Philosophy

Build the system that tells AI **what** and **how** to build — not just the code itself.

- **Guidelines** (`docs/guidelines/`) hold universal workflow and quality bars.
- **Skills** hold stack-specific tooling and patterns.
- **Tool adapters** (`AGENTS.md`, Cursor rules, Claude Code adapter) route assistants to the same source of truth.

Knowledge compounds when repeated mistakes become docs and docs become skills — each session starts with accumulated context, not from zero.

## Entry point

**[AGENTS.md](AGENTS.md)** — read this first in any AI assistant.

| Tool | Adapter |
|------|---------|
| Cursor, Copilot, Windsurf, Codex | `AGENTS.md` (+ optional tool rules or skills) |
| Claude Code | [CLAUDE.md](CLAUDE.md) → points to `AGENTS.md` |
| Google Antigravity | [GEMINI.md](GEMINI.md) + `AGENTS.md` (GEMINI wins on conflict in Antigravity) |

See [docs/tool-adapters.md](docs/tool-adapters.md) for install paths and merge order.

## What's included (Phase 1)

- **9 guideline docs** — `docs/guidelines/` (universal workflow + tracker-agnostic intake + comprehension gate)
- **13 stack skills** — `skills/stacks/<id>/` (tooling, DoD, routing)
- **3 core skills** — stack-detection, stack-loader, testing-universal
- **Slim registry** — detection only + universal DoD
- **Install script** — `./scripts/kit install --target=cursor|claude|codex|antigravity|both|all`
- **Tool adapters** — Codex (`~/.codex/AGENTS.md`), Antigravity (`~/.gemini/` + GEMINI.md) — Phase 1.6
- **Cursor user-rules dedup** — `sync-cursor-user-rules.sh` + `kit-user-rules.mdc` (skip duplicate guidelines)

Coming later: slash commands (Claude Code), pattern skill packs, hooks, CI.

## Quick start

```bash
git clone https://github.com/alexey-poimtsev/claude_dev.git ~/Projects/agent_dev_kit
cd ~/Projects/agent_dev_kit

./scripts/kit install --dry-run --target=all
./scripts/kit install --target=all
# or per tool:
./scripts/kit install --target=cursor
./scripts/kit install --target=claude
./scripts/kit install --target=codex
./scripts/kit install --target=antigravity
```

Kit scripts run with bash internally — your interactive shell (`$SHELL`) does not matter for `./scripts/kit`. See [docs/shell-commands.md](docs/shell-commands.md).

Then open any project. The assistant reads **AGENTS.md** and loads guidelines for the task.

## How it works

```
Your request
    ↓
AGENTS.md — intent + guideline routing (canonical)
    ↓
docs/guidelines/ — universal rules
    ↓
skills/stacks/<id>/ — technology-specific tooling and DoD
    ↓
.ai/ — plans (target project)
```

**User rules win.** Global Cursor rules override kit defaults when stricter.

## Guidelines index

| Doc | Purpose |
|-----|---------|
| [TRACKER.md](docs/guidelines/TRACKER.md) | work_ref, spec_key, intake without MCP |
| [SPECS.md](docs/guidelines/SPECS.md) | Spec-first — acceptance criteria before code |
| [Spec examples](docs/examples/specs/README.md) | Sample specs v1.0, v1.1, archive |
| [WORKFLOW.md](docs/guidelines/WORKFLOW.md) | Issue → spec → plan → implement → verify → PR |
| [COMPREHENSION.md](docs/guidelines/COMPREHENSION.md) | Handoff, Q&A, human sign-off — avoid skill degradation |
| [CODING.md](docs/guidelines/CODING.md) | Code style and quality |
| [TESTING.md](docs/guidelines/TESTING.md) | TDD and coverage |
| [VERIFICATION.md](docs/guidelines/VERIFICATION.md) | Completion gate — tests, lint, docs (separate agent) |
| [REVIEW.md](docs/guidelines/REVIEW.md) | Security and DoD review |
| [COMMITS.md](docs/guidelines/COMMITS.md) | Conventional commits |
| [GIT.md](docs/guidelines/GIT.md) | Branching and merge policy |
| [Shell commands](docs/shell-commands.md) | `./scripts/kit` from any shell |

## Architecture

See [docs/architecture.md](docs/architecture.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## References

- [How git-flow-next shipped 1.0 with AI](https://git-flow.sh/blog/posts/how-we-shipped-git-flow-next-1-0-with-ai/) — guidelines as the product, skills as executable workflow, compounding context across sessions.

## License

MIT — see [LICENSE](LICENSE).
