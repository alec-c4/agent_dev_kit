#!/usr/bin/env bash
# kit-env.sh — shared paths and bash runner for Agent Dev Kit scripts
set -euo pipefail

kit_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
  case "$dir" in
    */scripts/lib) echo "$(cd "$dir/../.." && pwd)" ;;
    */scripts) echo "$(cd "$dir/.." && pwd)" ;;
    *) echo "$(cd "$dir/.." && pwd)" ;;
  esac
}

kit_bash() {
  if command -v bash >/dev/null 2>&1; then
    command -v bash
  elif [[ -x /bin/bash ]]; then
    echo /bin/bash
  else
    echo "ERROR: bash is required to run Agent Dev Kit scripts" >&2
    return 1
  fi
}

kit_interactive_shell_name() {
  local base
  base="$(basename "${SHELL:-}")"
  case "$base" in
    fish|bash|zsh|sh|ksh|dash|nu) echo "$base" ;;
    "") echo "unknown" ;;
    *) echo "$base" ;;
  esac
}

kit_config_dir() {
  local xdg="${XDG_CONFIG_HOME:-$HOME/.config}"
  echo "$xdg/agent_dev_kit"
}

kit_config_file() {
  echo "$(kit_config_dir)/config.yaml"
}

kit_config_present() {
  [[ -f "$(kit_config_file)" ]]
}

run_kit_script() {
  local script_name="$1"
  shift
  local root runner script
  root="$(kit_root)"
  runner="$(kit_bash)"
  script="$root/scripts/$script_name"
  if [[ ! -f "$script" ]]; then
    echo "ERROR: missing kit script $script" >&2
    return 1
  fi
  exec "$runner" "$script" "$@"
}
