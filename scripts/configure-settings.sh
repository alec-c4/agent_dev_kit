#!/usr/bin/env bash
# configure-settings.sh — Apply kit config → Cursor cli-config + Claude settings
#
# Usage:
#   bash scripts/configure-settings.sh
#   bash scripts/configure-settings.sh --init-config
#   bash scripts/configure-settings.sh --target=claude --disable-attribution

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/configure_settings.py" "$@"
