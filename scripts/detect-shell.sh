#!/usr/bin/env bash
# detect-shell.sh — Report interactive shell vs kit script runner (bash)
#
# Usage:
#   ./scripts/kit shell-info
#   bash scripts/detect-shell.sh [--json]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-env.sh
source "$SCRIPT_DIR/lib/kit-env.sh"

JSON=false
for arg in "$@"; do
  case "$arg" in
    --json) JSON=true ;;
    --help|-h)
      echo "Usage: detect-shell.sh [--json]"
      exit 0
      ;;
  esac
done

INTERACTIVE="${SHELL:-unknown}"
INTERACTIVE_NAME="$(kit_interactive_shell_name)"
RUNNER="$(kit_bash)"

chain_hint() {
  case "$INTERACTIVE_NAME" in
    fish) echo "fish: use '; and' between commands (not &&)" ;;
    zsh|bash|sh|ksh|dash) echo "posix: use && between commands" ;;
    *) echo "use your shell's command chaining rules" ;;
  esac
}

if $JSON; then
  if command -v bun &>/dev/null; then
    bun -e "
      const o = {
        interactive_shell: process.argv[1],
        interactive_shell_path: process.argv[2],
        kit_script_runner: 'bash',
        kit_script_runner_path: process.argv[3],
        command_chain_hint: process.argv[4],
        kit_cli: './scripts/kit',
      };
      console.log(JSON.stringify(o, null, 2));
    " "$INTERACTIVE_NAME" "$INTERACTIVE" "$RUNNER" "$(chain_hint)"
  elif command -v jq &>/dev/null; then
    jq -n \
      --arg interactive_shell "$INTERACTIVE_NAME" \
      --arg interactive_shell_path "$INTERACTIVE" \
      --arg kit_script_runner_path "$RUNNER" \
      --arg command_chain_hint "$(chain_hint)" \
      '{
        interactive_shell: $interactive_shell,
        interactive_shell_path: $interactive_shell_path,
        kit_script_runner: "bash",
        kit_script_runner_path: $kit_script_runner_path,
        command_chain_hint: $command_chain_hint,
        kit_cli: "./scripts/kit"
      }'
  else
    python3 -c "
import json, sys
print(json.dumps({
  'interactive_shell': sys.argv[1],
  'interactive_shell_path': sys.argv[2],
  'kit_script_runner': 'bash',
  'kit_script_runner_path': sys.argv[3],
  'command_chain_hint': sys.argv[4],
  'kit_cli': './scripts/kit',
}, indent=2))
" "$INTERACTIVE_NAME" "$INTERACTIVE" "$RUNNER" "$(chain_hint)"
  fi
  exit 0
fi

echo "Interactive shell: $INTERACTIVE_NAME ($INTERACTIVE)"
echo "Kit script runner: bash ($RUNNER)"
echo "Chain hint: $(chain_hint)"
echo "Run kit scripts: ./scripts/kit <command> (from any interactive shell)"
