#!/usr/bin/env bash
# protect-secrets.sh — Block commands that expose secrets (fail-closed).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/kit-hook-common.sh
source "$HOOK_DIR/lib/kit-hook-common.sh"
kit_read_input
kit_require_parser
[[ -z "$KIT_HOOK_COMMAND" ]] && exit 0

if echo "$KIT_HOOK_COMMAND" | grep -qE '(cat|less|head|tail|bat)[[:space:]]+.*\.(env[^/[:space:]]*|pem|key|p12|pfx|jks|keystore)([[:space:]]|$|")'; then
  kit_block "read of a secrets file (.env*, .pem, .key, …)" \
    "The contents would enter the transcript, where they are no longer secret." \
    "Read the matching .example file for the key names, or ask the human for the value you need."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE 'git[[:space:]]+(add|commit).*\.(env[^/[:space:]]*|pem|key|secret)' && \
   ! echo "$KIT_HOOK_COMMAND" | grep -qE '\.env[^/[:space:]]*\.example'; then
  kit_block "commit of a secrets file" \
    "Once a secret is committed it stays in git history even after a later delete." \
    "Add the path to .gitignore and commit a .example file with placeholder values instead."
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE '(echo|printf|printenv)[[:space:]]+.*\$(AWS_|SECRET|TOKEN|PASSWORD|API_KEY|PRIVATE_KEY)'; then
  kit_block "print of a secret environment variable" \
    "Echoing the value copies it into the transcript and shell history." \
    "Check that the variable is set with: [ -n \"\$VAR\" ] && echo set"
fi
if echo "$KIT_HOOK_COMMAND" | grep -qE '(curl|wget).*(-H[[:space:]]+"Authorization:|--header[[:space:]]+"Authorization:).*Bearer[[:space:]]+[A-Za-z0-9._-]{20,}'; then
  kit_block "hardcoded Bearer token in a curl/wget call" \
    "A literal token in the command line lands in shell history and the transcript." \
    "Reference an environment variable instead: -H \"Authorization: Bearer \$TOKEN\""
fi
exit 0
