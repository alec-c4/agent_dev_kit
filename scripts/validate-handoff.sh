#!/usr/bin/env bash
# validate-handoff.sh — Structural checks on comprehension handoff markdown
#
# Usage:
#   ./scripts/validate-handoff.sh GH-58
#   ./scripts/validate-handoff.sh --file=.ai/work/GH-58-handoff.md
#   ./scripts/kit validate-handoff GH-58
#
# Validates sections and sign-off for standard/strict tiers. Does not judge Q&A quality.

set -euo pipefail

PROJECT_DIR="$(pwd)"
WORK_REF=""
HANDOFF_FILE=""
TIER=""

usage() {
  sed -n '2,10p' "$0"
}

for arg in "$@"; do
  case "$arg" in
    --file=*) HANDOFF_FILE="${arg#--file=}" ;;
    --tier=*) TIER="${arg#--tier=}" ;;
    --help|-h) usage; exit 0 ;;
    --*) echo "ERROR: unknown option: $arg" >&2; exit 1 ;;
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

sanitize_ref() {
  local s="$1"
  s="${s//\//-}"
  s="${s// /-}"
  printf '%s' "$s"
}

if [[ -z "$HANDOFF_FILE" ]]; then
  [[ -n "$WORK_REF" ]] || { echo "ERROR: work_ref or --file= required" >&2; usage >&2; exit 1; }
  SAFE_REF="$(sanitize_ref "$WORK_REF")"
  HANDOFF_FILE="$PROJECT_DIR/.ai/work/${SAFE_REF}-handoff.md"
  if [[ -f "$PROJECT_DIR/.ai/tracker.yaml" ]]; then
    HANDOFF_FILE="$PROJECT_DIR/$(python3 - "$PROJECT_DIR/.ai/tracker.yaml" "$SAFE_REF" <<'PY'
import sys
from pathlib import Path
ref = sys.argv[2]
path = Path(".ai") / "work" / f"{ref}-handoff.md"
try:
    import yaml
    data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
    wf = data.get("work_filename") or "work/{work_ref}-{kind}.md"
    rel = wf.replace("{work_ref}", ref).replace("{kind}", "handoff")
    path = Path(".ai") / rel
except ImportError:
    pass
print(path)
PY
)"
  fi
fi

[[ "$HANDOFF_FILE" != /* ]] && HANDOFF_FILE="$PROJECT_DIR/$HANDOFF_FILE"

[[ -f "$HANDOFF_FILE" ]] || {
  echo "ERROR: handoff not found: $HANDOFF_FILE" >&2
  exit 1
}

python3 - "$HANDOFF_FILE" "$TIER" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
tier_override = sys.argv[2].strip().lower()
text = path.read_text(encoding="utf-8")
errors: list[str] = []

def require(pattern: str, msg: str) -> None:
    if not re.search(pattern, text, re.MULTILINE | re.IGNORECASE):
        errors.append(msg)

require(r"^#\s+Handoff:", "missing H1 Handoff title")
require(r"\*\*Comprehension tier:\*\*", "missing Comprehension tier field")

tier_match = re.search(r"\*\*Comprehension tier:\*\*\s*(\w+)", text, re.IGNORECASE)
tier = (tier_override or (tier_match.group(1) if tier_match else "standard")).lower()

if tier not in ("minimal", "standard", "strict"):
    errors.append(f"unknown comprehension tier: {tier}")

if tier == "minimal":
    print(f"OK: minimal tier — structural gate skipped ({path})")
    sys.exit(0)

require(r"## What changed", "missing ## What changed")
require(r"## Data flow", "missing ## Data flow")
require(r"## Key files", "missing ## Key files")
require(r"## Comprehension Q&A", "missing ## Comprehension Q&A")
require(r"## Human sign-off", "missing ## Human sign-off")

qa_blocks = len(re.findall(r"^### Q\d+", text, re.MULTILINE))
expected_qa = 5 if tier == "strict" else 3
if qa_blocks < expected_qa:
    errors.append(f"expected at least {expected_qa} Q&A blocks (### Qn), found {qa_blocks}")

if not re.search(r"\*\*Signed:\*\*\s*\S", text):
    errors.append("missing Human sign-off Signed date")

if tier == "strict":
    require(r"\*\*Teach-back:\*\*", "strict tier requires Teach-back in Human sign-off")

if errors:
    print(f"FAIL: {path}", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    sys.exit(1)

print(f"OK: handoff structure valid ({tier}, {qa_blocks} Q&A, {path})")
PY
