# Architecture

Agent Dev Kit is **stack-agnostic** and **LLM-agnostic**. Universal rules live in guidelines; technology specifics live in **skills**.

## Separation of concerns

| Layer | Stack-specific? | Location |
|-------|-----------------|----------|
| Workflow, review, commits, git | No | `docs/guidelines/` |
| Stack detection signals | Minimal (file markers) | `registry/stacks.yaml` |
| Tooling, DoD overlay, skill routing | Yes | `skills/stacks/<id>/profile.yaml` |
| Framework patterns, security per stack | Yes | `skills/*` (packs) |
| Entry points | No | `AGENTS.md` (canonical), `CLAUDE.md` (Claude Code adapter) |

**Rule:** if it mentions a concrete technology (RSpec, Brakeman, pytest, ESLint, Phoenix, …), it belongs in a **skill**, not in guidelines or slim registry files.

## Layers

```
┌─────────────────────────────────────────────────────────┐
│  AGENTS.md (+ CLAUDE.md adapter)   (routers)             │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│  docs/guidelines/               (universal)               │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│  registry/stacks.yaml           (detect → stack_skill)  │
│  registry/dod.yaml              (universal DoD only)    │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│  skills/stacks/<id>/            (tooling + dod_overlay) │
│  skills/stack-detection|loader|testing-universal      │
│  skills/<pattern>/              (packs — Phase 2+)      │
└─────────────────────────────────────────────────────────┘
```

## Single source of truth

| Need | Source |
|------|--------|
| Workflow | `docs/guidelines/WORKFLOW.md` |
| Universal DoD | `registry/dod.yaml` |
| Stack DoD overlay | `skills/stacks/<id>/profile.yaml` → `dod_overlay` |
| Test/lint commands | `skills/stacks/<id>/profile.yaml` → `tooling` |
| Which stack matched | `scripts/detect-stack.sh` → `.claude/stack.profile.json` |
| Security per topic | `registry/topics.yaml` → skill stack files |

## Stack profile cache

```bash
bash scripts/detect-stack.sh --write-profile
# → .claude/stack.profile.json
```

After editing `skills/stacks/*/profile.yaml` or `registry/*.yaml`, run `bash scripts/compile_registry.sh`.

## User rules

Global Cursor rules and project rules override kit defaults when stricter.

## Extending

**New stack:** add `skills/stacks/foo/`, one line in `registry/stacks.yaml`, compile.

**New framework patterns:** add a skill under `skills/` and reference it from the stack profile — do not extend guidelines.

See [EXTENDING.md](EXTENDING.md) and [stack-detection.md](stack-detection.md).
