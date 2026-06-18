#!/usr/bin/env bash
# protect-secrets.sh — Block commands that expose secrets (fail-closed).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0

if echo "$KIT_HOOK_COMMAND" | grep -qE '(cat|less|head|tail|bat)[[:space:]]+.*\.(env[^/[:space:]]*|pem|key|p12|pfx|jks|keystore)([[:space:]]|$|")'; then
  kit_block "BLOCKED: reading a secrets file (.env*, .pem, .key, etc.). Confirm with the human first."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'git[[:space:]]+(add|commit).*\.(env[^/[:space:]]*|pem|key|secret)' && \
   ! echo "$KIT_HOOK_COMMAND" | grep -qE '\.env[^/[:space:]]*\.example'; then
  kit_block "BLOCKED: attempting to commit a secrets file. Add it to .gitignore instead."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE '(echo|printf|printenv)[[:space:]]+.*\$(AWS_|SECRET|TOKEN|PASSWORD|API_KEY|PRIVATE_KEY)'; then
  kit_block "BLOCKED: printing a secret environment variable."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE '(curl|wget).*(-H[[:space:]]+"Authorization:|--header[[:space:]]+"Authorization:).*Bearer[[:space:]]+[A-Za-z0-9._-]{20,}'; then
  kit_block "BLOCKED: hardcoded Bearer token in curl/wget. Use an env var reference instead."
fi
exit 0
