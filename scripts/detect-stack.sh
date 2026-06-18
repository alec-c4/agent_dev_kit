#!/usr/bin/env bash
# detect-stack.sh — Emit stack profile JSON from registry/stacks.yaml
#
# Usage:
#   bash scripts/detect-stack.sh
#   bash scripts/detect-stack.sh /path/to/app
#   bash scripts/detect-stack.sh --write-profile
#   bash scripts/detect-stack.sh --write-profile /path/to/app
#
# Requires: python3, PyYAML (pip install pyyaml)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WRITE_PROFILE=false
CWD="."

for arg in "$@"; do
  case "$arg" in
    --write-profile) WRITE_PROFILE=true ;;
    -h|--help)
      echo "Usage: $0 [--write-profile] [project-directory]"
      exit 0
      ;;
    *)
      if [[ "$arg" != --* ]]; then
        CWD="$arg"
      fi
      ;;
  esac
done

if ! command -v python3 &>/dev/null; then
  echo '{"error":"python3 is required for stack detection"}' >&2
  exit 1
fi

ARGS=(--cwd "$CWD" --kit-dir "$KIT_DIR")
$WRITE_PROFILE && ARGS+=(--write-profile)

exec python3 "$SCRIPT_DIR/detect_stack.py" "${ARGS[@]}"
