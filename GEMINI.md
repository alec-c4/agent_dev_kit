# Antigravity adapter

This repository is **[Agent Dev Kit](AGENTS.md)** — an LLM-agnostic developer kit.

Antigravity loads `GEMINI.md` and `AGENTS.md` at session start. **In Antigravity, this file overrides conflicting rules in AGENTS.md.** Universal workflow stays in [docs/guidelines/](docs/guidelines/).

## Quick routing

1. Read [AGENTS.md](AGENTS.md) for workflow and guidelines index.
2. Classify intent — [docs/guidelines/INTENT-ROUTING.md](docs/guidelines/INTENT-ROUTING.md) (plain text and workflows share one pipeline).
3. Non-trivial task: spec first — [docs/guidelines/SPECS.md](docs/guidelines/SPECS.md).
4. Detect stack: `./scripts/kit detect-stack --write-profile` → load `skills/stacks/<id>/`.
5. Task complete → verifier session — [docs/guidelines/VERIFICATION.md](docs/guidelines/VERIFICATION.md).

## Antigravity-specific

- **Manager vs Editor:** use Manager for parallel or long-running tasks; Editor for synchronous edits. Hand off with clear artifacts in `.ai/`.
- **Browser verify (optional):** for UI work, verify in the built-in browser when available — do not skip spec or verification gates.
- **Workflows (Phase 2+):** `.agents/workflows/` slash commands mirror Claude Code `/feature`, `/fix`, etc.

## Defer

Follow the developer's global rules when stricter. Do not duplicate Cursor user rules or shell syntax preferences here.

See [docs/tool-adapters.md](docs/tool-adapters.md) for install paths and skill locations.
