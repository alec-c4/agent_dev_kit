#!/usr/bin/env bash
# mark-review-passed.sh — Set review-passed flag(s) after human approves review.
#
# Usage:
#   bash hooks/mark-review-passed.sh [--target=claude|cursor|agents|all]
set -euo pipefail

TARGET="${KIT_REVIEW_TARGET:-all}"

for arg in "$@"; do
  case "$arg" in
    --target=*) TARGET="${arg#--target=}" ;;
    --help|-h)
      sed -n '2,6p' "$0"
      exit 0
      ;;
  esac
done

touch_flags() {
  local dir="$1"
  mkdir -p "$dir"
  touch "$dir/review-passed"
}

case "$TARGET" in
  claude) touch_flags ".claude" ;;
  cursor) touch_flags ".cursor" ;;
  agents) touch_flags ".agents" ;;
  all)
    touch_flags ".claude"
    touch_flags ".cursor"
    touch_flags ".agents"
    ;;
  *)
    echo "ERROR: --target must be claude, cursor, agents, or all" >&2
    exit 1
    ;;
esac

echo "Review flag set ($TARGET) — git commit allowed when review gate is enabled."
