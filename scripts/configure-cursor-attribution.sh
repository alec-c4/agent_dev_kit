#!/usr/bin/env bash
# configure-cursor-attribution.sh — Deprecated alias for configure-settings.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/configure_settings.py" "$@"
