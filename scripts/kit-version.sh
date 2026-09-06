#!/usr/bin/env bash
# kit-version.sh — what version of the kit is here, and what got installed
#
# `kit install` copies and symlinks into ~/.claude, ~/.agents and ~/.cursor.
# Once that has happened, "which kit am I actually running" is a question
# neither the checkout nor the install site can answer alone, so the install
# leaves a stamp and this reads both.
#
# Usage:
#   bash scripts/kit-version.sh          # human readable
#   bash scripts/kit-version.sh --json   # machine readable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-env.sh
source "$SCRIPT_DIR/lib/kit-env.sh"

KIT_DIR="$(kit_root)"
JSON=false

for arg in "$@"; do
  case "$arg" in
    --json) JSON=true ;;
    --help | -h)
      echo "Usage: $0 [--json]"
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

version="unknown"
if [[ -f "$KIT_DIR/VERSION" ]]; then
  version="$(tr -d '[:space:]' <"$KIT_DIR/VERSION")"
fi

commit=""
dirty=false
if git -C "$KIT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  commit="$(git -C "$KIT_DIR" rev-parse --short HEAD 2>/dev/null || true)"
  git -C "$KIT_DIR" diff --quiet HEAD 2>/dev/null || dirty=true
fi

stamp="$(kit_config_path install.json)"
installed_version=""
installed_commit=""
installed_at=""
installed_root=""
if [[ -f "$stamp" ]] && command -v jq &>/dev/null; then
  installed_version="$(jq -r '.version // ""' "$stamp" 2>/dev/null || true)"
  installed_commit="$(jq -r '.commit // ""' "$stamp" 2>/dev/null || true)"
  installed_at="$(jq -r '.installed_at // ""' "$stamp" 2>/dev/null || true)"
  installed_root="$(jq -r '.kit_root // ""' "$stamp" 2>/dev/null || true)"
fi

if $JSON; then
  jq -n \
    --arg version "$version" \
    --arg commit "$commit" \
    --argjson dirty "$dirty" \
    --arg kit_root "$KIT_DIR" \
    --arg stamp "$stamp" \
    --arg installed_version "$installed_version" \
    --arg installed_commit "$installed_commit" \
    --arg installed_at "$installed_at" \
    --arg installed_root "$installed_root" \
    '{
      version: $version,
      commit: (if $commit == "" then null else $commit end),
      dirty: $dirty,
      kit_root: $kit_root,
      install_stamp: (if $installed_version == "" then null else {
        path: $stamp,
        version: $installed_version,
        commit: (if $installed_commit == "" then null else $installed_commit end),
        installed_at: $installed_at,
        kit_root: $installed_root
      } end)
    }'
  exit 0
fi

echo "Agent Dev Kit $version"
if [[ -n "$commit" ]]; then
  echo "  commit:  $commit$($dirty && echo " (uncommitted changes)")"
fi
echo "  source:  $KIT_DIR"
if [[ -n "$installed_version" ]]; then
  echo "  install: $installed_version${installed_commit:+ ($installed_commit)} — $installed_at"
  if [[ "$installed_root" != "$KIT_DIR" ]]; then
    echo "  NOTE: installed from $installed_root, which is not this checkout"
  elif [[ -n "$commit" && -n "$installed_commit" && "$installed_commit" != "$commit" ]]; then
    echo "  NOTE: the checkout moved since the install — re-run: ./scripts/kit install"
  fi
else
  echo "  install: none recorded (run ./scripts/kit install)"
fi
