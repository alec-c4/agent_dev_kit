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

# Two directory spellings shipped: agent_dev_kit (tool settings) and
# agent-dev-kit (projects and lessons). The hyphenated form is canonical; the
# underscored one is still read so an existing install keeps working. Mirrors
# scripts/lib/kit_config_paths.py and packages/kit-runtime/src/kit-paths.ts —
# this copy read only the legacy name, so it saw nothing after a fresh install.
KIT_CONFIG_CANONICAL="agent-dev-kit"
KIT_CONFIG_LEGACY="agent_dev_kit"

kit_config_home() {
  echo "${XDG_CONFIG_HOME:-$HOME/.config}"
}

# Canonical directory for new files.
kit_config_dir() {
  echo "$(kit_config_home)/$KIT_CONFIG_CANONICAL"
}

# Path to read for a name, preferring canonical over the legacy directory.
kit_config_path() {
  local name="$1" home canonical legacy
  home="$(kit_config_home)"
  canonical="$home/$KIT_CONFIG_CANONICAL/$name"
  legacy="$home/$KIT_CONFIG_LEGACY/$name"
  if [[ -e "$canonical" ]]; then
    echo "$canonical"
  elif [[ -e "$legacy" ]]; then
    echo "$legacy"
  else
    echo "$canonical"
  fi
}

kit_config_file() {
  kit_config_path config.yaml
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
