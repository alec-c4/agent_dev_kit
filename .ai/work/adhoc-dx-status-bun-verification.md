# Verification: adhoc-dx-status-bun

**Work ref:** adhoc-dx-status-bun  
**Spec:** specs/dx-status-bun-spec.md v1.0  
**Commit:** f2bfbd2 (+ uncommitted handoff note)  
**Date:** 2026-08-03  
**Comprehension:** minimal (human skipped handoff/sign-off)

## Commands

| Check | Result | Evidence |
|-------|--------|----------|
| bun test (kit-runtime) | PASS | 23 pass, 0 fail |
| `./scripts/kit validate` | PASS | PASSED (0 warning(s)) |
| `./scripts/kit validate-skills --pack=core` | PASS | PASSED |
| Lint / typecheck | SKIP | No project-wide TS lint profile; Bun tests cover runtime |
| Docs sync | PASS | installation.md, shell-commands.md, WORKFLOW/SPECS/TRACKER/INTENT/COMPREHENSION updated |

## Spec conformance

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 golden detect-stack | PASS | `packages/kit-runtime/test/detect-stack.golden.test.ts` — 6 fixtures |
| AC-2 Bun missing → Python | PASS | `scripts/detect-stack.sh` Bun then `exec python3 detect_stack.py` |
| AC-3 CI setup-bun + golden | PASS | `.github/workflows/validate.yml` setup-bun + Golden parity step |
| AC-4 projects registry | PASS | `projects-registry.ts` + unit tests (block YAML, prune, atomic write) |
| AC-5 status --watch | PASS | `cli/status.ts` `watch(ai, { recursive: true }, …)` |
| AC-6 board loopback | PASS | `cli/board.ts` `hostname: HOST` with `127.0.0.1`; explicit `kit board` only |
| AC-7 spec_language + gates | PASS | `kit-config.ts` + status/board surface `spec_language`/`gates`; rejects `spec_locale`; unit tests |
| AC-8 mermaid pipeline | PASS | WORKFLOW.md mermaid backlog → milestone → … → gates |
| AC-9 agent-manager RFC | PASS | `.ai/backlog/items/rfc-agent-manager.md` |

## Comprehension gate

PASS (skipped): tier **minimal** by explicit human request «пропусти handoff».

## Follow-ups (non-blocking)

1. Investigate occasional `projects.yaml.lock` timeout on concurrent status.
2. After stability window: drop Python/Ruby fallbacks.

## Verdict

**PASS**
