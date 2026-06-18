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

if [[ -f "$PROJECT_DIR/.ai/tracker.yaml" ]]; then
  read -r OUTPUT TRACKER_PROVIDER <<EOF
$(python3 - "$PROJECT_DIR/.ai/tracker.yaml" "$SAFE_REF" <<'PY'
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
PY
EOF
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
  TITLE="$(printf '%s' "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('title',''))")"
  BODY="$(printf '%s' "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('body') or '')")"
  TRACKER_LINK="$(printf '%s' "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('url',''))")"
  SOURCE="gh issue view $id"
  return 0
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
