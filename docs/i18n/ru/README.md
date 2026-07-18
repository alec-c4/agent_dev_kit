---
locale: ru
canonical: README.md
---

# Agent Dev Kit

**Языки:** [English](../../../README.md) · **Русский** · [Español](../es/README.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](../../../LICENSE)

Универсальный developer kit для AI-assisted product engineering. **LLM-agnostic** и **stack-agnostic** — работает с Cursor, Claude Code, OpenAI Codex, Google Antigravity, Copilot, Windsurf и другими инструментами.

## Философия

Стройте систему, которая говорит AI **что** и **как** делать — а не только сам код.

Guidelines, skills и review criteria — это **продукт**. Сгенерированный код — выход. Знания накапливаются, когда повторяющиеся ошибки становятся документами, а документы — skills; каждая сессия начинается с накопленного контекста, а не с нуля.

| Слой | Роль |
|------|------|
| **Guidelines** (`docs/guidelines/`) | Универсальный workflow и планка качества |
| **Skills** (`packs/`) | Stack-specific tooling и patterns |
| **Tool adapters** (`AGENTS.md`, Cursor rules, Claude Code adapter) | Ведут ассистентов к одному source of truth |

## Принципы

Kit задаёт чёткие правила **как люди и агенты работают вместе**:

1. **Human as control plane** — разработчик отвечает за то, что уходит в production. Агенты усиливают работу, но не заменяют понимание. См. [COMPREHENSION.md](../../guidelines/COMPREHENSION.md).
2. **Force verification, not trust** — надёжная автоматизация снижает мониторинг ([automation-induced complacency](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.00225/full), Ako-Brew et al., 2019). Kit противодействует этому отдельным verifier-агентом, comprehension Q&A, human sign-off и опциональными review hooks — не rubber-stamping зелёного CI.
3. **Spec before code** — acceptance criteria и plan до implementation. См. [SPECS.md](../../guidelines/SPECS.md) и [WORKFLOW.md](../../guidelines/WORKFLOW.md).
4. **Test-driven by default** — red → green → refactor, если задача явно не пропускает тесты. См. [TESTING.md](../../guidelines/TESTING.md).
5. **Stack in skills, not guidelines** — RSpec, pytest, ESLint и подобный tooling живут в skills и stack profiles, а не в универсальных docs.
6. **User rules win** — глобальные Cursor rules и личные preferences перебивают kit defaults, если они строже.
7. **No agent attribution** — commits и PR остаются human-authored. См. [COMMITS.md](../../guidelines/COMMITS.md) и [tool-settings.md](../../tool-settings.md).

## Точка входа

**[AGENTS.md](../../../AGENTS.md)** — читайте первым в любом AI assistant.

| Tool | Adapter |
|------|---------|
| Cursor, Copilot, Windsurf, Codex | `AGENTS.md` (+ optional tool rules or skills) |
| Claude Code | [CLAUDE.md](../../../CLAUDE.md) → указывает на `AGENTS.md` |
| Google Antigravity | [GEMINI.md](../../../GEMINI.md) + `AGENTS.md` (GEMINI wins on conflict в Antigravity) |

См. [tool-adapters.md](../../tool-adapters.md) для install paths и merge order.

## Что уже готово

Готово к установке и использованию:

### Guidelines и workflow

11 документов в `docs/guidelines/` — workflow, specs, tracker-agnostic intake, comprehension gate, testing, verification, review, git, commits. Ключевые gates:

| Gate | Doc | Что обеспечивает |
|------|-----|------------------|
| Comprehension | [COMPREHENSION.md](../../guidelines/COMPREHENSION.md) | Human понимает изменение до verify |
| Verification | [VERIFICATION.md](../../guidelines/VERIFICATION.md) | Отдельный agent запускает tests, lint, doc truth |
| Review | [REVIEW.md](../../guidelines/REVIEW.md) | Security и definition-of-done до merge |

### Skill packs

Deploy через `./scripts/kit install` или `./scripts/kit deploy-skills --pack=…`:

| Pack | Skills | Роль |
|------|--------|------|
| [core](../../../packs/core/) | 32 | Stack detection, profiles, intent routing, workflow shortcuts, work intake, comprehension gate |
| [patterns](../../../packs/patterns/) | 25 | Framework и DevOps patterns (Flutter, Docker, Svelte, …) |
| [topics](../../../packs/topics/) | 4 | Cross-cutting topics (security, LLM, RAG, MCP) |

**Stack packs** (optional slices — см. [packs/README.md](../../../packs/README.md)): `rails`, `node`, `python`, `go`, `elixir`, `devops`, `astro`, `tauri`, `swift`, `kotlin`, `react-native`, `flutter`. Установка: `./scripts/kit install --pack=core,rails`.

### Kit CLI и automation

| Feature | Command / doc |
|---------|---------------|
| Install | `./scripts/kit install --target=all` — [installation.md](../../installation.md) |
| Validate | `./scripts/kit validate` (CI on push) |
| Stack detection | `./scripts/kit detect-stack --write-profile` |
| Tracker intake | `./scripts/kit intake` → `.ai/work/{ref}-analysis.md` — [TRACKER.md](../../guidelines/TRACKER.md) |
| Tool settings | `./scripts/kit configure` — permissions и attribution для Cursor + Claude — [tool-settings.md](../../tool-settings.md) |
| Shell reference | [shell-commands.md](../../shell-commands.md) |

### Tool adapters и agents

- **Cursor** — path-scoped `kit-*.mdc` rules + user-rules dedup
- **Claude Code** — [CLAUDE.md](../../../CLAUDE.md) adapter + `agents/` personas (developer, architect, auditor, explore, orchestrator)
- **Codex** — `~/.codex/AGENTS.md`
- **Antigravity** — [GEMINI.md](../../../GEMINI.md) + `.agents/`

См. [tool-adapters.md](../../tool-adapters.md).

### Hooks (opt-in)

Shared shell hooks для Claude Code и Cursor — block dangerous commands, protect secrets, optional review gate before commit. См. [hooks.md](../../hooks.md).

```bash
./scripts/kit install --target=both --with-hooks --with-review-gate
```

### Registry и quality

- Slim detection registry (`registry/stacks.yaml`) и universal DoD
- Skills review process — [skills-review.md](../../skills-review.md) (automated → agent → human sign-off in PR)

## Roadmap

Ещё не shipped; в планах:

| Phase | Item | Notes |
|-------|------|-------|
| **4b** | Skills content depth | Layer 2/3 review для devops, mobile, astro и остальных packs |
| **4c** | Pack-dependent MCP presets | `--pack=rails` → merge recommended MCP servers в Cursor/Claude config |
| **5** | Project scaffolds | `templates/project-*` для новых repos |
| **5** | Linear / Jira cache | `sync-tracker` сегодня только GitHub; другие providers через paste/export |
| **5** | Antigravity hooks | Reuse shell scripts когда IDE hook API стабилизируется |
| **5** | Copilot instructions | `.github/instructions/` pattern-scoped rules (last) |
| **—** | Doc translations | Больше переводов guidelines — см. [docs/i18n/README.md](../README.md) |

Implementation tracking живёт вне этого repo (не коммитится сюда).

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

Kit scripts внутри используют bash — ваш interactive shell (`$SHELL`) не важен для `./scripts/kit`. См. [shell-commands.md](../../shell-commands.md).

Откройте любой project. Assistant читает **AGENTS.md** и подгружает guidelines для задачи.

## Как это работает

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

**User rules win.** Global Cursor rules перебивают kit defaults, если они строже.

## Guidelines index

| Doc | Purpose |
|-----|---------|
| [TRACKER.md](../../guidelines/TRACKER.md) | work_ref, spec_key, intake without MCP |
| [SPECS.md](../../guidelines/SPECS.md) | Spec-first — acceptance criteria before code |
| [Spec examples](../../examples/specs/README.md) | Sample specs v1.0, v1.1, archive |
| [WORKFLOW.md](../../guidelines/WORKFLOW.md) | Issue → spec → plan → implement → verify → PR |
| [COMPREHENSION.md](../../guidelines/COMPREHENSION.md) | Handoff, Q&A, human sign-off — avoid skill degradation |
| [CODING.md](../../guidelines/CODING.md) | Code style and quality |
| [TESTING.md](../../guidelines/TESTING.md) | TDD and coverage |
| [VERIFICATION.md](../../guidelines/VERIFICATION.md) | Completion gate — tests, lint, docs (separate agent) |
| [REVIEW.md](../../guidelines/REVIEW.md) | Security and DoD review |
| [COMMITS.md](../../guidelines/COMMITS.md) | Conventional commits |
| [GIT.md](../../guidelines/GIT.md) | Branching and merge policy |
| [Shell commands](../../shell-commands.md) | `./scripts/kit` from any shell |
| [Hooks](../../hooks.md) | Claude Code + Cursor shell hooks (opt-in install) |
| [Installation](../../installation.md) | Install targets, packs, hooks, verify |

Guidelines на английском — canonical для agents. Переводы overview: [docs/i18n](../README.md).

## Architecture

См. [architecture.md](../../architecture.md).

## Contributing

См. [CONTRIBUTING.md](../../../CONTRIBUTING.md). Переводы docs — [docs/i18n/README.md](../README.md).

## References

- [How git-flow-next shipped 1.0 with AI](https://git-flow.sh/blog/posts/how-we-shipped-git-flow-next-1-0-with-ai/) — guidelines as the product, skills as executable workflow, compounding context across sessions.
- [Automation-induced complacency potential](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.00225/full) (Ako-Brew et al., 2019) — reliable automation reduces monitoring; kit gates (comprehension, verification, review hooks) keep the developer checking what AI produces.

## License

MIT — см. [LICENSE](../../../LICENSE).
