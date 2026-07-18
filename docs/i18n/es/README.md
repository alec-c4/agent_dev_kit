---
locale: es
canonical: README.md
---

# Agent Dev Kit

**Idiomas:** [English](../../../README.md) · [Русский](../ru/README.md) · **Español**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](../../../LICENSE)

Kit de desarrollo universal para product engineering asistido por IA. **LLM-agnostic** y **stack-agnostic** — funciona con Cursor, Claude Code, OpenAI Codex, Google Antigravity, Copilot, Windsurf y otros.

## Filosofía

Construye el sistema que le dice a la IA **qué** y **cómo** construir — no solo el código.

Guidelines, skills y review criteria son el **producto**. El código generado es la salida. El conocimiento se acumula cuando los errores repetidos se convierten en docs y los docs en skills; cada sesión empieza con contexto acumulado, no desde cero.

| Capa | Rol |
|------|-----|
| **Guidelines** (`docs/guidelines/`) | Workflow universal y barreras de calidad |
| **Skills** (`packs/`) | Tooling y patterns específicos del stack |
| **Tool adapters** (`AGENTS.md`, Cursor rules, Claude Code adapter) | Dirigen a los asistentes al mismo source of truth |

## Principios

El kit es explícito sobre **cómo trabajan juntos humanos y agentes**:

1. **Human as control plane** — el desarrollador es dueño de lo que llega a producción. Los agentes amplían el trabajo; no reemplazan la comprensión. Ver [COMPREHENSION.md](../../guidelines/COMPREHENSION.md).
2. **Force verification, not trust** — la automatización fiable reduce el monitoreo ([automation-induced complacency](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.00225/full), Ako-Brew et al., 2019). El kit contrarresta esto con un agente verificador separado, comprehension Q&A, human sign-off y review hooks opcionales — no rubber-stamping de CI verde.
3. **Spec before code** — acceptance criteria y plan antes de la implementación. Ver [SPECS.md](../../guidelines/SPECS.md) y [WORKFLOW.md](../../guidelines/WORKFLOW.md).
4. **Test-driven by default** — red → green → refactor salvo que la tarea omita tests explícitamente. Ver [TESTING.md](../../guidelines/TESTING.md).
5. **Stack in skills, not guidelines** — RSpec, pytest, ESLint y tooling similar viven en skills y stack profiles, no en docs universales.
6. **User rules win** — las Cursor rules globales y preferencias personales prevalecen sobre kit defaults cuando son más estrictas.
7. **No agent attribution** — commits y PR permanecen human-authored. Ver [COMMITS.md](../../guidelines/COMMITS.md) y [tool-settings.md](../../tool-settings.md).

## Punto de entrada

**[AGENTS.md](../../../AGENTS.md)** — léelo primero en cualquier AI assistant.

| Tool | Adapter |
|------|---------|
| Cursor, Copilot, Windsurf, Codex | `AGENTS.md` (+ optional tool rules or skills) |
| Claude Code | [CLAUDE.md](../../../CLAUDE.md) → apunta a `AGENTS.md` |
| Google Antigravity | [GEMINI.md](../../../GEMINI.md) + `AGENTS.md` (GEMINI wins on conflict en Antigravity) |

Ver [tool-adapters.md](../../tool-adapters.md) para install paths y merge order.

## Disponible hoy

Listo para instalar y usar:

### Guidelines y workflow

11 docs en `docs/guidelines/` — workflow, specs, tracker-agnostic intake, comprehension gate, testing, verification, review, git, commits. Gates clave:

| Gate | Doc | Qué exige |
|------|-----|-----------|
| Comprehension | [COMPREHENSION.md](../../guidelines/COMPREHENSION.md) | El humano entiende el cambio antes de verify |
| Verification | [VERIFICATION.md](../../guidelines/VERIFICATION.md) | Agente separado ejecuta tests, lint, doc truth |
| Review | [REVIEW.md](../../guidelines/REVIEW.md) | Security y definition-of-done antes del merge |

### Skill packs

Deploy con `./scripts/kit install` o `./scripts/kit deploy-skills --pack=…`:

| Pack | Skills | Rol |
|------|--------|-----|
| [core](../../../packs/core/) | 32 | Stack detection, profiles, intent routing, workflow shortcuts, work intake, comprehension gate |
| [patterns](../../../packs/patterns/) | 25 | Framework y DevOps patterns (Flutter, Docker, Svelte, …) |
| [topics](../../../packs/topics/) | 4 | Cross-cutting topics (security, LLM, RAG, MCP) |

**Stack packs** (slices opcionales — ver [packs/README.md](../../../packs/README.md)): `rails`, `node`, `python`, `go`, `elixir`, `devops`, `astro`, `tauri`, `swift`, `kotlin`, `react-native`, `flutter`. Instalar con `./scripts/kit install --pack=core,rails`.

### Kit CLI y automation

| Feature | Command / doc |
|---------|---------------|
| Install | `./scripts/kit install --target=all` — [installation.md](../../installation.md) |
| Validate | `./scripts/kit validate` (CI on push) |
| Stack detection | `./scripts/kit detect-stack --write-profile` |
| Tracker intake | `./scripts/kit intake` → `.ai/work/{ref}-analysis.md` — [TRACKER.md](../../guidelines/TRACKER.md) |
| Tool settings | `./scripts/kit configure` — permissions y attribution para Cursor + Claude — [tool-settings.md](../../tool-settings.md) |
| Shell reference | [shell-commands.md](../../shell-commands.md) |

### Tool adapters y agents

- **Cursor** — path-scoped `kit-*.mdc` rules + user-rules dedup
- **Claude Code** — [CLAUDE.md](../../../CLAUDE.md) adapter + `agents/` personas (developer, architect, auditor, explore, orchestrator)
- **Codex** — `~/.codex/AGENTS.md`
- **Antigravity** — [GEMINI.md](../../../GEMINI.md) + `.agents/`

Ver [tool-adapters.md](../../tool-adapters.md).

### Hooks (opt-in)

Shared shell hooks para Claude Code y Cursor — block dangerous commands, protect secrets, optional review gate before commit. Ver [hooks.md](../../hooks.md).

```bash
./scripts/kit install --target=both --with-hooks --with-review-gate
```

### Registry y quality

- Slim detection registry (`registry/stacks.yaml`) y universal DoD
- Skills review process — [skills-review.md](../../skills-review.md) (automated → agent → human sign-off in PR)

## Roadmap

Aún no shipped; planificado:

| Phase | Item | Notes |
|-------|------|-------|
| **4b** | Skills content depth | Layer 2/3 review para devops, mobile, astro y packs restantes |
| **4c** | Pack-dependent MCP presets | `--pack=rails` → merge recommended MCP servers en Cursor/Claude config |
| **5** | Project scaffolds | `templates/project-*` para nuevos repos |
| **5** | Linear / Jira cache | `sync-tracker` hoy solo GitHub; otros providers vía paste/export |
| **5** | Antigravity hooks | Reuse shell scripts cuando el IDE hook API sea estable |
| **5** | Copilot instructions | `.github/instructions/` pattern-scoped rules (last) |
| **—** | Doc translations | Más traducciones de guidelines — ver [docs/i18n/README.md](../README.md) |

El tracking de implementación vive fuera de este repo (no se commitea aquí).

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

Los kit scripts usan bash internamente — tu interactive shell (`$SHELL`) no importa para `./scripts/kit`. Ver [shell-commands.md](../../shell-commands.md).

Abre cualquier project. El assistant lee **AGENTS.md** y carga guidelines para la tarea.

## Cómo funciona

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

**User rules win.** Las Cursor rules globales prevalecen sobre kit defaults cuando son más estrictas.

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

Guidelines en inglés — canonical para agents. Traducciones overview: [docs/i18n](../README.md).

## Architecture

Ver [architecture.md](../../architecture.md).

## Contributing

Ver [CONTRIBUTING.md](../../../CONTRIBUTING.md). Traducciones de docs — [docs/i18n/README.md](../README.md).

## References

- [How git-flow-next shipped 1.0 with AI](https://git-flow.sh/blog/posts/how-we-shipped-git-flow-next-1-0-with-ai/) — guidelines as the product, skills as executable workflow, compounding context across sessions.
- [Automation-induced complacency potential](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.00225/full) (Ako-Brew et al., 2019) — reliable automation reduces monitoring; kit gates (comprehension, verification, review hooks) keep the developer checking what AI produces.

## License

MIT — ver [LICENSE](../../../LICENSE).
