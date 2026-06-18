#!/usr/bin/env bash
# warm-stack-profile.sh — Warm stack profile at session start (fail-open).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"

if [[ -f Gemfile || -f package.json || -f go.mod || -f pyproject.toml || -f requirements.txt || -f Cargo.toml || -f mix.exs ]]; then
  KIT_ROOT="$(kit_find_root || true)"
  if [[ -n "$KIT_ROOT" && -f "$KIT_ROOT/scripts/kit" ]]; then
    bash "$KIT_ROOT/scripts/kit" detect-stack --write-profile 2>/dev/null || true
  fi
fi
exit 0
