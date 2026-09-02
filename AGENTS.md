# Agent Dev Kit

Universal developer kit for AI-assisted product engineering. Works with **Cursor**, **Claude Code**, **OpenAI Codex**, **Google Antigravity**, **Copilot**, **Windsurf**, and other assistants.

Supplements the developer's global rules (`~/.cursor/rules/`). **On conflict, user rules win.**

**Token dedup (Cursor):** run `./scripts/kit sync-rules` after install — see [docs/cursor-user-rules.md](docs/cursor-user-rules.md).

**Tracker-agnostic intake:** [docs/guidelines/TRACKER.md](docs/guidelines/TRACKER.md) — paste ticket into `.ai/work/{work_ref}-analysis.md`; MCP/API optional.

**Shell:** Kit scripts run via `./scripts/kit` (bash inside) from any interactive shell — see [docs/shell-commands.md](docs/shell-commands.md). For ad-hoc commands, use the developer's `$SHELL` (user `fish-shell.mdc` or equivalent wins).

## First steps

1. Classify intent: feature, bug, refactor, audit, or question — skill `intent-router` or [docs/guidelines/INTENT-ROUTING.md](docs/guidelines/INTENT-ROUTING.md) (plain text and `/commands` use the same pipeline).
2. If a ticket exists: set **work_ref** and **spec_key** — [docs/guidelines/TRACKER.md](docs/guidelines/TRACKER.md).
3. Read the matching guideline from `docs/guidelines/`.
4. Detect stack — `./scripts/kit detect-stack --write-profile`; load `skills/stacks/<id>/` (see `docs/stack-detection.md`).
5. Load feedback: `.ai/work/{work_ref}-findings.md` (treat `open`/`regressed` **block** rows as spec-weight constraints) and up to 20 stack-matching lessons from `.ai/lessons.md` plus `~/.config/agent-dev-kit/lessons.yaml`.
6. For non-trivial work: write a **spec** (`.ai/specs/*-spec.md` or legacy `.ai/issue-*-spec.md`), get approval, then plan and code — see [docs/guidelines/SPECS.md](docs/guidelines/SPECS.md).

## Guidelines index

| File | Use when |
|------|----------|
| [docs/guidelines/TRACKER.md](docs/guidelines/TRACKER.md) | work_ref, spec_key, intake without MCP, optional `.ai/tracker.yaml` |
| [docs/guidelines/SPECS.md](docs/guidelines/SPECS.md) | Before implementation — acceptance criteria |
| [docs/examples/specs/](docs/examples/specs/README.md) | Worked spec examples (new, fix, archive) |
| [docs/guidelines/WORKFLOW.md](docs/guidelines/WORKFLOW.md) | Task flow, planning, PR |
| [docs/guidelines/INTENT-ROUTING.md](docs/guidelines/INTENT-ROUTING.md) | Plain text vs slash commands — classify, clarify, hints |
| [docs/guidelines/COMPREHENSION.md](docs/guidelines/COMPREHENSION.md) | Human comprehension gate — handoff, Q&A, anti-degradation |
| [docs/guidelines/CODING.md](docs/guidelines/CODING.md) | Implementation |
| [docs/guidelines/TESTING.md](docs/guidelines/TESTING.md) | Tests, TDD |
| [docs/guidelines/VERIFICATION.md](docs/guidelines/VERIFICATION.md) | Task done — separate agent: tests, lint, docs |
| [docs/guidelines/REVIEW.md](docs/guidelines/REVIEW.md) | Pre-commit / PR review |
| [docs/guidelines/COMMITS.md](docs/guidelines/COMMITS.md) | Commit messages |
| [docs/guidelines/GIT.md](docs/guidelines/GIT.md) | Branches, merge policy |
| [docs/shell-commands.md](docs/shell-commands.md) | Kit CLI (`./scripts/kit`); interactive shell via `$SHELL` |

**Shipped language:** default `process_references: omit` — see [Shipped language](#shipped-language) below.

## Definition of Done

Checklist: universal `registry/dod.yaml` + stack `skills/stacks/<id>/profile.yaml` → `dod_overlay`.

## Planning artifacts

Store in `.ai/` (target project, not committed to kit by default):

- `.ai/specs/{spec_key}-spec.md` (recommended) or legacy `.ai/issue-{n}-spec.md`
- `.ai/work/{work_ref}-analysis.md`, `-plan.md`, `-verification.md`, `-findings.md`
- `.ai/lessons.md` (project lessons; prefer committing this file)
- `.ai/task-*.md` when no tracker
- `.ai/pr-summary.md`

See [.ai/README.md](.ai/README.md).

## Architecture

[docs/architecture.md](docs/architecture.md) — layers, registry, install targets, tool adapters.

## Tool adapters

| Tool | Entry file | Install target |
|------|------------|----------------|
| Any assistant | **AGENTS.md** (this file) | — |
| Cursor | `templates/cursor/rules/kit-*.mdc` + `kit-user-rules.manifest.json` | `./scripts/kit install --target=cursor` |
| Claude Code | [CLAUDE.md](CLAUDE.md) | `./scripts/kit install --target=claude` |
| OpenAI Codex CLI | **AGENTS.md** (native) | `./scripts/kit install --target=codex` |
| Google Antigravity | [GEMINI.md](GEMINI.md) + **AGENTS.md** | `./scripts/kit install --target=antigravity` |
| All supported | — | `./scripts/kit install --target=all` |

Full matrix: [docs/tool-adapters.md](docs/tool-adapters.md).

## Do not

- Duplicate user global rules (semantic commits, TDD, git branching, **shell syntax** for interactive commands).
- Add AI attribution to commits or PRs.
- Commit secrets, machine-specific paths, or personal tool injection blocks to the kit repo.

## Shipped language

Default (`.ai/kit.yaml` → `process_references: omit`, or missing key/file): do **not** put implementation-plan, stage/phase, or other generated planning jargon into product code, comments, public docs, commit messages, or PR bodies.

| Forbidden in shipped text | Examples |
|---------------------------|----------|
| Delivery phases / stages | `Phase 0`, `stage 2`, `MVP` as product copy |
| Kit / plan jargon | `AC-1`, `work_ref`, handoff, DoD as product copy |
| Generated artifacts | paths like `.ai/work/*-plan.md`, “per implementation plan” |
| Agent noise | Cursor/Claude attribution in commits or PRs |

Planning stays under `.ai/` (or gitignored paths). Set `process_references: allow` only when the project explicitly wants kit jargon in shipped text. Stricter user global rules still win.

Details: [CODING.md](docs/guidelines/CODING.md#shipped-language), [COMMITS.md](docs/guidelines/COMMITS.md#shipped-language).
