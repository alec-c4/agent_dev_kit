# Agent Dev Kit

**Languages:** **English** · [Русский](docs/i18n/ru/README.md) · [Español](docs/i18n/es/README.md) · [Translation guide](docs/i18n/README.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Universal developer kit for AI-assisted product engineering. **LLM-agnostic** and **stack-agnostic** — works with Cursor, Claude Code, OpenAI Codex, Google Antigravity, Copilot, Windsurf, and others.

## Philosophy

Build the system that tells AI **what** and **how** to build — not just the code itself.

Guidelines, skills, and review criteria are the **product**. Generated code is the output. Knowledge compounds when repeated mistakes become docs and docs become skills — each session starts with accumulated context, not from zero.

| Layer | Role |
|-------|------|
| **Guidelines** (`docs/guidelines/`) | Universal workflow and quality bars |
| **Skills** (`packs/`) | Stack-specific tooling and patterns |
| **Tool adapters** (`AGENTS.md`, Cursor rules, Claude Code adapter) | Route assistants to the same source of truth |

## Principles

The kit is opinionated about **how humans and agents work together**:

1. **Human as control plane** — the developer owns what ships. Agents amplify work; they do not replace understanding. See [COMPREHENSION.md](docs/guidelines/COMPREHENSION.md).
2. **Force verification, not trust** — highly reliable automation makes people monitor less ([automation-induced complacency](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.00225/full), Ako-Brew et al., 2019). The kit counters this with a separate verifier agent, comprehension Q&A, human sign-off, and optional commit review hooks — not rubber-stamping green CI.
3. **Spec before code** — acceptance criteria and plan before implementation. See [SPECS.md](docs/guidelines/SPECS.md) and [WORKFLOW.md](docs/guidelines/WORKFLOW.md).
4. **Test-driven by default** — red → green → refactor unless the task explicitly skips tests. See [TESTING.md](docs/guidelines/TESTING.md).
5. **Stack in skills, not guidelines** — RSpec, pytest, ESLint, and similar tooling live in skills and stack profiles, not universal docs.
6. **User rules win** — global Cursor rules and personal preferences override kit defaults when stricter.
7. **No agent attribution** — commits and PRs stay human-authored. See [COMMITS.md](docs/guidelines/COMMITS.md) and [tool-settings.md](docs/tool-settings.md).

## Entry point

**[AGENTS.md](AGENTS.md)** — read this first in any AI assistant.

| Tool | Adapter |
|------|---------|
| Cursor, Copilot, Windsurf, Codex | `AGENTS.md` (+ optional tool rules or skills) |
| Claude Code | [CLAUDE.md](CLAUDE.md) → points to `AGENTS.md` |
| Google Antigravity | [GEMINI.md](GEMINI.md) + `AGENTS.md` (GEMINI wins on conflict in Antigravity) |

See [docs/tool-adapters.md](docs/tool-adapters.md) for install paths and merge order.

## Shipped today

Ready to install and use:

### Guidelines and workflow

11 docs in `docs/guidelines/` — workflow, specs, tracker-agnostic intake, comprehension gate, testing, verification, review, git, commits. Key gates:

| Gate | Doc | What it enforces |
|------|-----|------------------|
| Comprehension | [COMPREHENSION.md](docs/guidelines/COMPREHENSION.md) | Human understands the change before verify |
| Verification | [VERIFICATION.md](docs/guidelines/VERIFICATION.md) | Separate agent runs tests, lint, doc truth |
| Review | [REVIEW.md](docs/guidelines/REVIEW.md) | Security and definition-of-done before merge |

### Skill packs

Deploy with `./scripts/kit install` or `./scripts/kit deploy-skills --pack=…`:

| Pack | Skills | Role |
|------|--------|------|
| [core](packs/core/) | 32 | Stack detection, profiles, intent routing, workflow shortcuts, work intake, comprehension gate |
| [patterns](packs/patterns/) | 25 | Framework and DevOps patterns (Flutter, Docker, Svelte, …) |
| [topics](packs/topics/) | 4 | Cross-cutting topics (security, LLM, RAG, MCP) |

**Stack packs** (optional slices — see [packs/README.md](packs/README.md)): `rails`, `node`, `python`, `go`, `elixir`, `devops`, `astro`, `tauri`, `swift`, `kotlin`, `react-native`, `flutter`. Install with `./scripts/kit install --pack=core,rails`.

### Kit CLI and automation

| Feature | Command / doc |
|---------|---------------|
| Install | `./scripts/kit install --target=all` — [installation.md](docs/installation.md) |
| Validate | `./scripts/kit validate` (CI on push) |
| Stack detection | `./scripts/kit detect-stack --write-profile` |
| Tracker intake | `./scripts/kit intake` → `.ai/work/{ref}-analysis.md` — [TRACKER.md](docs/guidelines/TRACKER.md) |
| Tool settings | `./scripts/kit configure` — permissions and attribution for Cursor + Claude — [tool-settings.md](docs/tool-settings.md) |
| Shell reference | [shell-commands.md](docs/shell-commands.md) |

### Tool adapters and agents

- **Cursor** — path-scoped `kit-*.mdc` rules + user-rules dedup
- **Claude Code** — [CLAUDE.md](CLAUDE.md) adapter + `agents/` personas (developer, architect, auditor, explore, orchestrator)
- **Codex** — `~/.codex/AGENTS.md`
- **Antigravity** — [GEMINI.md](GEMINI.md) + `.agents/`

See [tool-adapters.md](docs/tool-adapters.md).

### Hooks (opt-in)

Shared shell hooks for Claude Code and Cursor — block dangerous commands, protect secrets, optional review gate before commit. See [hooks.md](docs/hooks.md).

```bash
./scripts/kit install --target=both --with-hooks --with-review-gate
```

### Registry and quality

- Slim detection registry (`registry/stacks.yaml`) and universal DoD
- Skills review process — [skills-review.md](docs/skills-review.md) (automated → agent → human sign-off in PR)

## Roadmap

Not shipped yet; planned next:

| Phase | Item | Notes |
|-------|------|-------|
| **4b** | Skills content depth | Layer 2/3 review for devops, mobile, astro, and remaining packs |
| **4c** | Pack-dependent MCP presets | `--pack=rails` → merge recommended MCP servers into Cursor/Claude config |
| **5** | Project scaffolds | `templates/project-*` for new repos |
| **5** | Linear / Jira cache | `sync-tracker` today supports GitHub only; other providers via paste/export |
| **5** | Antigravity hooks | Reuse shell scripts when IDE hook API is stable |
| **5** | Copilot instructions | `.github/instructions/` pattern-scoped rules (last) |
| **—** | Doc translations | More guideline locales — see [docs/i18n/README.md](docs/i18n/README.md) |

Implementation tracking lives outside this repo (not committed here).

## Quick start

```bash
git clone https://github.com/alec-c4/agent_dev_kit.git ~/Projects/agent_dev_kit
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
| [Hooks](docs/hooks.md) | Claude Code + Cursor shell hooks (opt-in install) |
| [Installation](docs/installation.md) | Install targets, packs, hooks, verify |

## Architecture

See [docs/architecture.md](docs/architecture.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## References

- [How git-flow-next shipped 1.0 with AI](https://git-flow.sh/blog/posts/how-we-shipped-git-flow-next-1-0-with-ai/) — guidelines as the product, skills as executable workflow, compounding context across sessions.
- [Automation-induced complacency potential](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.00225/full) (Ako-Brew et al., 2019) — reliable automation reduces monitoring; kit gates (comprehension, verification, review hooks) keep the developer checking what AI produces.

## License

MIT — see [LICENSE](LICENSE).
