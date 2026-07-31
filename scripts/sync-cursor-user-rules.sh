#!/usr/bin/env bash
# sync-cursor-user-rules.sh — Build ~/.cursor/kit-user-rules.manifest.json
#
# Prefers Bun; falls back to python3.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUN_CLI="$KIT_DIR/packages/kit-runtime/src/cli/sync-rules.ts"

if [[ ! -f "$KIT_DIR/registry/cursor-user-rules.json" ]]; then
  bash "$SCRIPT_DIR/compile_registry.sh"
fi

if command -v bun &>/dev/null && [[ -f "$BUN_CLI" ]]; then
  exec bun "$BUN_CLI" "$@"
fi

exec python3 "$SCRIPT_DIR/sync_cursor_user_rules.py" "$@"
