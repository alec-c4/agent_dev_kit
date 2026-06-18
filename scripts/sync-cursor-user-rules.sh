#!/usr/bin/env bash
# sync-cursor-user-rules.sh — Build ~/.cursor/kit-user-rules.manifest.json
#
# Scans user Cursor rules (~/.cursor/rules/*.mdc, excluding kit-*) and records
# which kit guideline files the agent should NOT re-read (token dedup).
#
# Usage:
#   bash scripts/sync-cursor-user-rules.sh
#   bash scripts/sync-cursor-user-rules.sh --dry-run
#   bash scripts/sync-cursor-user-rules.sh --rules-dir ~/.cursor/rules --rules-dir .cursor/rules

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f "$KIT_DIR/registry/cursor-user-rules.json" ]]; then
  bash "$SCRIPT_DIR/compile_registry.sh"
fi

exec python3 "$SCRIPT_DIR/sync_cursor_user_rules.py" "$@"
