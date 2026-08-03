# Handoff: DX status Bun

**Work ref:** adhoc-dx-status-bun  
**Comprehension tier:** minimal  
**Spec:** specs/dx-status-bun-spec.md v1.0  
**Commit:** f2bfbd2  

**Note:** Human explicitly skipped handoff / sign-off («пропусти handoff») — tier lowered to minimal.
## What changed

- Added `packages/kit-runtime` (Bun): detect-stack, compile, configure, sync-rules, status/board, tracker helpers.
- Kit CLI prefers Bun with Ruby/Python fallback; `kit status` / `kit board` / `kit register`.
- Global projects registry (`~/.config/agent-dev-kit/projects.yaml`) with prune + atomic write.
- Configurable gates catalog (`registry/gates.yaml`); SDD guideline bumps (clarify, milestones, AC↔plan).
- Removed unused `configure-*.sh` wrappers; CI runs Bun golden detect-stack tests.

## Data flow

Agent/human work still lands in project `.ai/` markdown. Status engine scans those files and infers pipeline stage. `kit status --watch` / `kit board` re-read on change (SSE poll). Global registry only lists project roots; it is not a second tracker.

## Key files

| Path | Role |
|------|------|
| `packages/kit-runtime/src/detect-stack.ts` | Bun stack detection (golden vs Python) |
| `packages/kit-runtime/src/status.ts` | Pipeline stage inference |
| `packages/kit-runtime/src/projects-registry.ts` | Global projects.yaml I/O |
| `packages/kit-runtime/src/cli/board.ts` | Loopback status board |
| `scripts/kit` | CLI routing to Bun/bash |
| `docs/guidelines/WORKFLOW.md` | Mermaid pipeline + consistency check |
| `registry/gates.yaml` | Gate catalog defaults |

## Decisions

- Bun + bash as target runtimes; keep Python/Ruby as transitional fallback (no hard cutover).
- Board binds `127.0.0.1` only; explicit start; no SvelteKit.
- Product slices named `milestone`; field `spec_language` (not `spec_locale`).
- Agent-manager deferred to backlog RFC.

## If it breaks

- Detect-stack: run `bun test` in `packages/kit-runtime` (golden parity).
- Status wrong stage: check `.ai/work/*` headers and spec `**Status:**`.
- Registry lock timeout: remove stale `~/.config/agent-dev-kit/projects.yaml.lock` if a crash left it.
- Board: confirm port 8787 free; must be loopback.

## Manual verification (from spec)

| AC | Scenario | Human result |
|----|----------|--------------|
| AC-5 / AC-6 *(human-verify)* | Run `./scripts/kit status` and optionally `./scripts/kit board`; confirm stages and loopback URL | *(human fills PASS/FAIL)* |

## Comprehension Q&A

Agent generates questions; human answers before sign-off. Agents must not answer for the human.

### Q1
**Question:** Why does `kit board` bind only to `127.0.0.1`, and what risk would binding `0.0.0.0` create?  
**Human answer:** Чтобы обеспечить доступ только с локальной машины (не открывать board в сеть).

### Q2
**Question:** How does the kit decide a work item’s pipeline stage without a separate database — what inputs does the scanner use?  
**Human answer:** По данным в md-файлах (`.ai/work`, specs и связанные артефакты).

### Q3
**Question:** What happens if Bun is not installed when someone runs `kit detect-stack` after a kit pull (symlink install)?  
**Human answer:** Fallback на Python.

## Human sign-off

Required for tier **standard**. Verifier treats missing sign-off as FAIL.

- **Files I read:** *(paths — at least one from Key files)*
- **I can explain:** *(one sentence in your own words)*
- **Signed:** *(YYYY-MM-DD)*
