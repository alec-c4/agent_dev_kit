# Spec: DX status Bun

**Document version:** 1.0
**Status:** approved
**Task type:** new
**Spec key:** dx-status-bun
**Work ref:** adhoc-dx-status-bun
**Tracker link:** —
**Supersedes:** —
**Milestone:** m1-runtime-board
**spec_language:** en

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2026-07-31 | — | Initial epic: bash+Bun runtime, registry, realtime status, gates taxonomy |

## Goal

Reduce kit runtimes to bash + Bun, expose realtime project/task status via CLI or localhost board, and add backlog/milestone/gates taxonomy without a second writable tracker.

## Scope

- In scope: Bun runtime with transitional legacy fallback; detect-stack golden parity; global projects registry; `kit status` / `kit board`; `spec_language`; configurable gates including duplication severity; SDD guideline bumps; agent-manager RFC in backlog only.
- Out of scope: SvelteKit app; agent swarm runtime; writable board; permanent Ruby/Python after drop phase.

## Acceptance criteria

- [ ] **AC-1:** Given Bun is installed, when `kit detect-stack` runs on each `scripts/fixtures/minimal-*`, then the emitted profile (excluding `detected_at`) matches the Python implementation byte-for-byte on canonical JSON.
- [ ] **AC-2:** Given Bun is missing, when `kit detect-stack` runs, then the command falls back to the legacy Python path and still succeeds on a known fixture.
- [ ] **AC-3:** Given CI validate workflow, when a PR adds Bun paths, then the workflow installs Bun and runs Bun detect-stack golden tests.
- [ ] **AC-4:** Given `~/.config/agent-dev-kit/projects.yaml`, when `kit register` or intake/detect-stack/status runs in a project, then the project root is upserted with `last_seen_at`; missing paths are pruned; writes are atomic (temp + rename) and lock-safe.
- [ ] **AC-5:** Given `kit status --watch`, when a watched `.ai/` artifact changes stage evidence, then the CLI prints an updated status within a short interval without restart.
- [ ] **AC-6:** Given `kit board`, when started, then it binds `127.0.0.1` only, does not auto-start from install, and serves project/task status over HTTP+SSE.
- [ ] **AC-7:** Given project `.ai/kit.yaml`, when `spec_language` and `gates` (including `duplication.severity`) are set, then guidelines and status tooling honor them; field is not named `spec_locale`.
- [ ] **AC-8:** Given docs WORKFLOW, when a newcomer reads them, then a mermaid diagram shows backlog → milestone → pipeline → gate suite.
- [ ] **AC-9:** Given kit backlog, when the epic ships, then an RFC item exists for multi-agent manager and is not implemented.

## Edge cases

- Symlink install: missing Bun must not hard-fail detect-stack until drop phase.
- Board must refuse or warn if bind is non-loopback without explicit override (v1: no override or override with warning).

## Non-goals

- EARS grammar; SvelteKit; Python/Ruby as permanent peers after drop phase.

## Constraints

- Target runtimes after drop: bash + Bun only.
- Human ack required before deleting audited files.
- Board is read-only over `.ai/`.

## Open questions

- None (locked in plan).
