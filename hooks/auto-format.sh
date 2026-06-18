#!/usr/bin/env bash
# auto-format.sh — Run formatter on edited file when available (fail-open).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
FILE="$KIT_HOOK_FILE"
[[ -z "$FILE" ]] && exit 0
[[ ! -f "$FILE" ]] && exit 0

ext="${FILE##*.}"
case "$ext" in
  rb)
    command -v standardrb &>/dev/null && standardrb --fix "$FILE" 2>/dev/null || true
    command -v rubocop &>/dev/null && rubocop --autocorrect-all "$FILE" 2>/dev/null || true
    ;;
  js|jsx|ts|tsx|mjs|cjs)
    command -v eslint &>/dev/null && eslint --fix "$FILE" 2>/dev/null || true
    ;;
  py)
    command -v ruff &>/dev/null && { ruff format "$FILE" 2>/dev/null || true; ruff check --fix "$FILE" 2>/dev/null || true; }
    ;;
  go)
    command -v gofmt &>/dev/null && gofmt -w "$FILE" 2>/dev/null || true
    ;;
  rs)
    command -v rustfmt &>/dev/null && rustfmt "$FILE" 2>/dev/null || true
    ;;
  json)
    if command -v jq &>/dev/null; then
      tmp="$(mktemp)"
      jq . "$FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$FILE" || rm -f "$tmp"
    fi
    ;;
esac
exit 0
