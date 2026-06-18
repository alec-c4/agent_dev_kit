---
name: tauri-patterns
description: Tauri desktop patterns — commands, IPC, Rust backend, webview security. Load after stacks/tauri profile.
user-invokable: false
---

# Tauri patterns

Load after [stacks/tauri](../stacks/tauri/SKILL.md).

## Architecture

- **Commands** (`#[tauri::command]`) as the IPC boundary — validate all inputs in Rust.
- Keep filesystem, network, and OS access in Rust; frontend calls commands, not raw APIs.
- **Capabilities** / allowlist (Tauri v2) — least privilege; deny by default.

## Frontend

- Use the project's UI stack (React, Svelte, etc.) in `src/`; share types cautiously across IPC.
- Never embed secrets in frontend bundle; load config via Rust at runtime when needed.

## Rust backend

- `src-tauri/` — thin command handlers delegate to modules; use `thiserror` for errors.
- Long IO on background threads or async runtime; do not block the main thread on network.

## Security

- CSP and Tauri security config reviewed on new commands that expose paths or shell.
- Code signing and updater keys outside repo; document release pipeline in project README.

## Testing

- Rust: `cargo test` in `src-tauri/`; frontend tests per stack profile.
- Smoke-test packaged build before release.

## References

- [Tauri docs](https://v2.tauri.app/)
