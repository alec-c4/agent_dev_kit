#!/usr/bin/env bash
# intake-work-item.sh — Write .ai/work/{work_ref}-analysis.md (paste or gh fetch)
#
# Usage:
#   bash scripts/intake-work-item.sh GH-58 --paste <<'EOF'
#   ticket title and body
#   EOF
#   bash scripts/intake-work-item.sh GH-58 --file=ticket.md
#   bash scripts/intake-work-item.sh GH-58              # tries gh when ref is GH-N or numeric
#   ./scripts/kit intake GH-58 --paste
#
# Exit 0 = analysis file written. Exit 1 = clear error (no silent API guess).

set -euo pipefail

PROJECT_DIR="$(pwd)"
WORK_REF=""
PASTE_FILE=""
USE_STDIN=false
DRY_RUN=false
SPEC_KEY=""

usage() {
  sed -n '2,12p' "$0"
  echo
  echo "Writes: .ai/work/{work_ref}-analysis.md (or path from .ai/tracker.yaml)"
}

for arg in "$@"; do
  case "$arg" in
    --paste) USE_STDIN=true ;;
    --file=*) PASTE_FILE="${arg#--file=}" ;;
    --spec-key=*) SPEC_KEY="${arg#--spec-key=}" ;;
    --dry-run) DRY_RUN=true ;;
    --help|-h) usage; exit 0 ;;
    --*) echo "ERROR: unknown option: $arg" >&2; usage >&2; exit 1 ;;
    *)
      if [[ -z "$WORK_REF" ]]; then
        WORK_REF="$arg"
      else
        echo "ERROR: unexpected argument: $arg" >&2
        exit 1
      fi
      ;;
  esac
done

[[ -n "$WORK_REF" ]] || { echo "ERROR: work_ref required (e.g. GH-58, adhoc-export-csv)" >&2; usage >&2; exit 1; }

sanitize_ref() {
  local s="$1"
  s="${s//\//-}"
  s="${s// /-}"
  printf '%s' "$s"
}

SAFE_REF="$(sanitize_ref "$WORK_REF")"
TRACKER_PROVIDER="none"
OUTPUT=".ai/work/${SAFE_REF}-analysis.md"
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUN_WORK_PATH="$KIT_DIR/packages/kit-runtime/src/cli/work-path.ts"
BUN_CACHE_PATH="$KIT_DIR/packages/kit-runtime/src/cli/cache-path.ts"
BUN_CACHE_LOOKUP="$KIT_DIR/packages/kit-runtime/src/cli/cache-lookup.ts"

# Both resolvers print two lines: the artifact path, then the provider.
# `mapfile` is bash 4+ and macOS ships bash 3.2, so split the lines with sed.
resolve_work_path_python() {
  python3 - "$PROJECT_DIR/.ai/tracker.yaml" "$SAFE_REF" <<'PYSCRIPT'
import sys
from pathlib import Path

ref = sys.argv[2]
path = Path(".ai") / "work" / f"{ref}-analysis.md"
provider = "none"
try:
    import yaml

    data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
    provider = data.get("provider") or "none"
    wf = data.get("work_filename") or "work/{work_ref}-{kind}.md"
    rel = wf.replace("{work_ref}", ref).replace("{kind}", "analysis")
    path = Path(".ai") / rel
except ImportError:
    pass
print(path)
print(provider)
PYSCRIPT
}

resolve_cache_path_python() {
  python3 - "$PROJECT_DIR/.ai/tracker.yaml" <<'PYSCRIPT'
import sys
from pathlib import Path

try:
    import yaml

    data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
    print(Path(".ai") / (data.get("cache_file") or "tracker-cache.json"))
except ImportError:
    print(".ai/tracker-cache.json")
PYSCRIPT
}

lookup_cache_python() {
  python3 - "$1" "$WORK_REF" <<'PYSCRIPT'
import json
import sys
from pathlib import Path

try:
    data = json.loads(Path(sys.argv[1]).read_text())
except (OSError, ValueError):
    data = {}
ref = sys.argv[2]
for item in data.get("items") or []:
    if item.get("work_ref") == ref:
        print(item.get("title") or "")
        print(item.get("url") or "")
        print(item.get("status") or "")
        break
else:
    print("")
    print("")
    print("")
PYSCRIPT
}

if [[ -f "$PROJECT_DIR/.ai/tracker.yaml" ]]; then
  if command -v bun &>/dev/null && [[ -f "$BUN_WORK_PATH" ]]; then
    _wp="$(bun "$BUN_WORK_PATH" "$PROJECT_DIR" "$SAFE_REF" analysis)"
  else
    _wp="$(resolve_work_path_python)"
  fi
  _wp_path="$(printf '%s\n' "$_wp" | sed -n '1p')"
  _wp_provider="$(printf '%s\n' "$_wp" | sed -n '2p')"
  [[ -n "$_wp_path" ]] && OUTPUT="$_wp_path"
  [[ -n "$_wp_provider" ]] && TRACKER_PROVIDER="$_wp_provider"
fi

TITLE=""
BODY=""
TRACKER_LINK=""
SOURCE=""

load_paste() {
  if [[ -n "$PASTE_FILE" ]]; then
    [[ -f "$PASTE_FILE" ]] || { echo "ERROR: file not found: $PASTE_FILE" >&2; exit 1; }
    BODY="$(cat "$PASTE_FILE")"
    SOURCE="file:$PASTE_FILE"
    return 0
  fi
  if $USE_STDIN; then
    BODY="$(cat)"
    SOURCE="stdin"
    return 0
  fi
  return 1
}

fetch_github() {
  local id=""
  if [[ "$WORK_REF" =~ ^[Gg][Hh]-([0-9]+)$ ]]; then
    id="${BASH_REMATCH[1]}"
  elif [[ "$WORK_REF" =~ ^[0-9]+$ ]]; then
    id="$WORK_REF"
    WORK_REF="GH-${id}"
  else
    return 1
  fi
  command -v gh &>/dev/null || return 1
  local json
  json="$(gh issue view "$id" --json title,body,url 2>/dev/null)" || return 1
  if command -v jq &>/dev/null; then
    TITLE="$(printf '%s' "$json" | jq -r '.title // ""')"
    BODY="$(printf '%s' "$json" | jq -r '.body // ""')"
    TRACKER_LINK="$(printf '%s' "$json" | jq -r '.url // ""')"
  elif command -v bun &>/dev/null; then
    TITLE="$(printf '%s' "$json" | bun -e 'const d=JSON.parse(await Bun.stdin.text()); process.stdout.write(d.title||"")')"
    BODY="$(printf '%s' "$json" | bun -e 'const d=JSON.parse(await Bun.stdin.text()); process.stdout.write(d.body||"")')"
    TRACKER_LINK="$(printf '%s' "$json" | bun -e 'const d=JSON.parse(await Bun.stdin.text()); process.stdout.write(d.url||"")')"
  else
    TITLE="$(printf '%s' "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('title',''))")"
    BODY="$(printf '%s' "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('body') or '')")"
    TRACKER_LINK="$(printf '%s' "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('url',''))")"
  fi
  SOURCE="gh issue view $id"
  return 0
}
enrich_from_cache() {
  local cache_path="$PROJECT_DIR/.ai/tracker-cache.json"
  if [[ -f "$PROJECT_DIR/.ai/tracker.yaml" ]]; then
    if command -v bun &>/dev/null && [[ -f "$BUN_CACHE_PATH" ]]; then
      cache_path="$PROJECT_DIR/$(bun "$BUN_CACHE_PATH" "$PROJECT_DIR")"
    else
      cache_path="$PROJECT_DIR/$(resolve_cache_path_python)"
    fi
  fi
  [[ -f "$cache_path" ]] || return 0
  local _cl
  if command -v bun &>/dev/null && [[ -f "$BUN_CACHE_LOOKUP" ]]; then
    _cl="$(bun "$BUN_CACHE_LOOKUP" "$cache_path" "$WORK_REF")"
  else
    _cl="$(lookup_cache_python "$cache_path")"
  fi
  # Three lines: title, url, status. Each may legitimately contain spaces, so
  # split by line rather than by word.
  CACHE_TITLE="$(printf '%s\n' "$_cl" | sed -n '1p')"
  CACHE_URL="$(printf '%s\n' "$_cl" | sed -n '2p')"
  CACHE_STATUS="$(printf '%s\n' "$_cl" | sed -n '3p')"
  [[ -z "$TITLE" && -n "$CACHE_TITLE" ]] && TITLE="$CACHE_TITLE"
  [[ -z "$TRACKER_LINK" && -n "$CACHE_URL" ]] && TRACKER_LINK="$CACHE_URL"
  if [[ -n "$CACHE_STATUS" && "$SOURCE" != gh* ]]; then
    SOURCE="${SOURCE:+$SOURCE; }tracker-cache ($CACHE_STATUS)"
  fi
}

if load_paste; then
  :
elif [[ "$TRACKER_PROVIDER" == "github" ]] || [[ "$WORK_REF" =~ ^[Gg][Hh]-[0-9]+$ ]] || [[ "$WORK_REF" =~ ^[0-9]+$ ]]; then
  if fetch_github; then
    :
  else
    echo "ERROR: no paste and could not fetch GitHub issue for $WORK_REF." >&2
    echo "  Paste: ./scripts/kit intake $WORK_REF --paste <<'EOF'" >&2
    echo "  Or: gh auth login" >&2
    exit 1
  fi
else
  echo "ERROR: no paste provided for work_ref $WORK_REF." >&2
  echo "  Use --paste or --file=path ([TRACKER.md](docs/guidelines/TRACKER.md) intake step 1)." >&2
  exit 1
fi

[[ -n "$BODY" ]] || { echo "ERROR: empty intake body" >&2; exit 1; }

enrich_from_cache

if [[ -z "$TITLE" ]]; then
  TITLE="$(printf '%s' "$BODY" | head -n 1 | sed 's/^#\+ //;s/^//')"
  [[ -n "$TITLE" ]] || TITLE="Analysis for $WORK_REF"
fi

SPEC_LINE=""
[[ -n "$SPEC_KEY" ]] && SPEC_LINE="**Spec key:** $SPEC_KEY"

mkdir -p "$(dirname "$OUTPUT")"

CONTENT="# Analysis: $TITLE

**Work ref:** $WORK_REF
${SPEC_LINE}
**Tracker link:** ${TRACKER_LINK:-—}
**Source:** $SOURCE

## Problem

$BODY

## Affected areas

*(Agent: explore codebase and list modules, files, or endpoints.)*
"

if $DRY_RUN; then
  echo "Would write: $OUTPUT"
  printf '%s\n' "$CONTENT"
  exit 0
fi

printf '%s' "$CONTENT" > "$OUTPUT"
echo "Wrote $OUTPUT"
