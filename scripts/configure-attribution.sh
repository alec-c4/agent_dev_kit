#!/usr/bin/env bash
# configure-attribution.sh — Sync kit-config attribution → Cursor + Claude Code configs
#
# Usage:
#   bash scripts/configure-attribution.sh --disable-attribution
#   bash scripts/configure-attribution.sh --target=claude --disable-attribution
#   bash scripts/configure-attribution.sh --dry-run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/configure_settings.py" "$@"
