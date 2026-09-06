# Changelog

Notable changes to Agent Dev Kit. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The version that matters to a user is the one in `VERSION`, reported by
`./scripts/kit version` alongside the commit an install came from.

## [Unreleased]

### Fixed

- `kit install` aborted on a fresh clone and destroyed a project's `.ai/`. Five
  install paths linked the kit's own gitignored `.ai/` into the destination,
  and the deploy helper replaces a destination outright.
- `kit check-patterns` raised blocking findings against the kit's own skills in
  any project that had deployed them.
- `kit lessons list` could not show a pending lesson, so the id needed to
  acknowledge one was visible only in the output that created it (`--all`).
- `kit deploy-hooks` marked the sourced hook library executable, leaving a mode
  change in the kit checkout after every run.
- The bash config-path helper read only the pre-rename `agent_dev_kit`
  directory, disagreeing with its Python and TypeScript siblings.
- AGENTS.md and WORKFLOW.md linked to `.ai/README.md`, which is in no clone.
  The `.ai/` contract now lives in `docs/guidelines/PLANNING-ARTIFACTS.md`.

### Added

- `kit smoke` — every command run against a throwaway `HOME`, including an
  install from an export of `HEAD` rather than the working checkout.
- `kit version` and a `VERSION` file; `kit install` records a stamp so the
  command can say whether an install still matches the checkout it came from.
- Failure-pattern rows for kit-path escapes, assistant attribution in shipped
  text, bash 4 builtins on macOS, and committed agent artifacts.

### Changed

- Catalog rows now honour `stack`, and can declare `severity: warn` to be
  reported and recorded without failing a gate.

## [0.1.0]

First tracked version. Everything below already shipped; this entry records the
state the kit is in at the point versioning started, not a release of new work.

### Added

- **CLI** — `./scripts/kit` dispatches every kit script from any interactive
  shell (fish, zsh, bash): `install`, `compile`, `validate`, `validate-skills`,
  `smoke`, `deploy-skills`, `deploy-workflows`, `deploy-hooks`, `intake`,
  `sync-tracker`, `validate-handoff`, `detect-stack`, `register`, `status`,
  `board`, `findings`, `lessons`, `check-patterns`, `verify-docs`, `sync-rules`,
  `configure`, `shell-info`, `version`, `run`.
- **Tool adapters** — Cursor (`kit-*.mdc` rules and user-rules dedup), Claude
  Code (`CLAUDE.md` plus `agents/` personas), Codex, and Antigravity.
- **Skills** — workflow skills (`feature`, `fix`, `plan`, `review`, `ship`,
  `resolve-task`, `spec-lint`, `retrospect`, `changelog`, `comprehension-check`,
  `intent-router`) and stack skills for Rails, Node, Python, Go, Elixir, Astro,
  Tauri, Swift, Kotlin, React Native, Flutter, and DevOps.
- **Stack detection** — `registry/stacks.yaml` drives `kit detect-stack`, with
  golden-parity tests between the Bun and Python implementations.
- **Feedback loop** — findings ledger, lessons (project and opt-in
  user-global), and a failure-pattern catalog, wired into a verification gate.
- **Hooks** — dangerous-command blocking, secret protection, commit-scope and
  branch-protection checks, review gate, and auto-format.
- **Doc freshness** — `kit verify-docs` checks the package and link claims a
  skill makes against the upstream registries, on a weekly CI schedule.
- **Command smoke tests** — `kit smoke` runs every command against a throwaway
  `HOME` and asserts an artifact or output shape, not just an exit code.

[Unreleased]: https://github.com/alec-c4/agent_dev_kit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/alec-c4/agent_dev_kit/releases/tag/v0.1.0
