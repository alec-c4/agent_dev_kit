#!/usr/bin/env bash
# validate-docs-i18n.sh — locale registry and translation file checks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCALES_JSON="$KIT_DIR/registry/locales.json"
ERRORS=0

err() { echo "ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }
ok() { echo "  ok: $*"; }

if ! command -v jq &>/dev/null; then
  err "jq is required for docs i18n validation"
  exit 1
fi

if [[ ! -f "$LOCALES_JSON" ]]; then
  err "missing registry/locales.json — run: ./scripts/kit compile"
  exit 1
fi

default_locale="$(jq -r '.default_locale // empty' "$LOCALES_JSON")"
if [[ -z "$default_locale" ]]; then
  err "locales.json: missing default_locale"
else
  ok "default locale: $default_locale"
fi

while IFS= read -r code; do
  readme="$(jq -r --arg c "$code" '.locales[$c].readme // empty' "$LOCALES_JSON")"
  if [[ -z "$readme" ]]; then
    err "locale $code: missing readme path"
    continue
  fi
  if [[ ! -f "$KIT_DIR/$readme" ]]; then
    err "locale $code: readme not found: $readme"
  else
    ok "locale $code readme: $readme"
  fi

  if [[ "$code" == "$default_locale" ]]; then
    continue
  fi

  path_count="$(jq -r --arg c "$code" '.locales[$c].translations | length' "$LOCALES_JSON")"
  if [[ "$path_count" -eq 0 ]]; then
    err "locale $code: no translations[] entries"
    continue
  fi

  idx=0
  while [[ $idx -lt $path_count ]]; do
    rel="$(jq -r --arg c "$code" --argjson i "$idx" '.locales[$c].translations[$i].path // empty' "$LOCALES_JSON")"
    idx=$((idx + 1))
    [[ -n "$rel" ]] || continue
    full="$KIT_DIR/$rel"
    if [[ ! -f "$full" ]]; then
      err "locale $code: missing translation: $rel"
      continue
    fi
    if ! head -n 20 "$full" | grep -q '^canonical:'; then
      err "locale $code: $rel missing canonical front matter"
      continue
    fi
    source_path="$(jq -r --arg c "$code" --arg p "$rel" '
      .locales[$c].translations[] | select(.path == $p) | .source
    ' "$LOCALES_JSON")"
    if [[ -z "$source_path" || "$source_path" == "null" ]]; then
      err "locale $code: $rel missing source in locales.yaml"
      continue
    fi
    if [[ ! -f "$KIT_DIR/$source_path" ]]; then
      err "locale $code: canonical source missing: $source_path"
      continue
    fi
    ok "locale $code translation: $rel → $source_path"
  done
done < <(jq -r '.locales | keys[]' "$LOCALES_JSON")

if [[ $ERRORS -gt 0 ]]; then
  echo "docs i18n validation FAILED: $ERRORS error(s)" >&2
  exit 1
fi

exit 0
