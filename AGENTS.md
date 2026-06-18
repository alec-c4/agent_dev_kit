# Agent Dev Kit

Universal developer kit for AI-assisted product engineering. Works with **Cursor**, **Claude Code**, **Copilot**, **Windsurf**, and other assistants.

Supplements the developer's global rules (`~/.cursor/rules/`). **On conflict, user rules win.**

## First steps

1. Classify intent: feature, bug, refactor, audit, or question.
2. Read the matching guideline from `docs/guidelines/`.
3. Detect stack — run detect-stack; load `skills/stacks/<id>/` (see `docs/stack-detection.md`).
4. For non-trivial work: write a **spec** (`.ai/*-spec.md`), get approval, then plan and code — see [docs/guidelines/SPECS.md](docs/guidelines/SPECS.md).

## Guidelines index

| File | Use when |
|------|----------|
| [docs/guidelines/SPECS.md](docs/guidelines/SPECS.md) | Before implementation — acceptance criteria |
| [docs/examples/specs/](docs/examples/specs/README.md) | Worked spec examples (new, fix, archive) |
| [docs/guidelines/WORKFLOW.md](docs/guidelines/WORKFLOW.md) | Task flow, planning, PR |
| [docs/guidelines/CODING.md](docs/guidelines/CODING.md) | Implementation |
| [docs/guidelines/TESTING.md](docs/guidelines/TESTING.md) | Tests, TDD |
| [docs/guidelines/VERIFICATION.md](docs/guidelines/VERIFICATION.md) | Task done — separate agent: tests, lint, docs |
| [docs/guidelines/REVIEW.md](docs/guidelines/REVIEW.md) | Pre-commit / PR review |
| [docs/guidelines/COMMITS.md](docs/guidelines/COMMITS.md) | Commit messages |
| [docs/guidelines/GIT.md](docs/guidelines/GIT.md) | Branches, merge policy |

## Definition of Done

Checklist: universal `registry/dod.yaml` + stack `skills/stacks/<id>/profile.yaml` → `dod_overlay`.

## Planning artifacts

Store in `.ai/` (target project, not committed to kit by default):

- `.ai/issue-{n}-analysis.md`
- `.ai/issue-{n}-spec.md`
- `.ai/issue-{n}-plan.md`
- `.ai/issue-{n}-verification.md`
- `.ai/pr-summary.md`

See [.ai/README.md](.ai/README.md).

## Architecture

[docs/architecture.md](docs/architecture.md) — layers, registry, install targets, tool adapters.

## Tool adapters

| Tool | Entry file | Install target |
|------|------------|----------------|
| Any assistant | **AGENTS.md** (this file) | — |
| Cursor | `templates/cursor/rules/kit-*.mdc` | `bash scripts/install.sh --target=cursor` |
| Claude Code | [CLAUDE.md](CLAUDE.md) | `bash scripts/install.sh --target=claude` |

Guidelines in `docs/guidelines/` are canonical — adapters only route to them.

## Do not

- Duplicate user global rules (semantic commits, TDD, git branching, fish shell hints).
- Add AI attribution to commits or PRs.
- Commit secrets, machine-specific paths, or personal tool injection blocks to the kit repo.
