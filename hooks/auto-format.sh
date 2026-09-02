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
    # standard depends on rubocop, so both binaries resolve on a Standard
    # project. Running rubocop after standardrb reformats the file a second
    # time with default RuboCop rules — pick one.
    if command -v standardrb &>/dev/null; then
      standardrb --fix "$FILE" 2>/dev/null || true
    elif command -v rubocop &>/dev/null; then
      rubocop --autocorrect-all "$FILE" 2>/dev/null || true
    fi
    ;;
  js|jsx|ts|tsx|mjs|cjs)
    # Prefer the project's pinned eslint over whatever is on PATH.
    if [[ -x "node_modules/.bin/eslint" ]]; then
      node_modules/.bin/eslint --fix "$FILE" 2>/dev/null || true
    elif command -v eslint &>/dev/null; then
      eslint --fix "$FILE" 2>/dev/null || true
    fi
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
