#!/usr/bin/env bash
# sync-tracker-cache.sh — Snapshot active tracker items to .ai/tracker-cache.json
#
# Usage:
#   ./scripts/sync-tracker-cache.sh [--dry-run]
#   ./scripts/kit sync-tracker [--dry-run]
#
# Requires: gh CLI + auth when provider is github.
# Output: .ai/tracker-cache.json (gitignore in target projects)

set -euo pipefail

PROJECT_DIR="$(pwd)"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      sed -n '2,10p' "$0"
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

TRACKER_YAML="$PROJECT_DIR/.ai/tracker.yaml"
python3 - "$PROJECT_DIR" "$TRACKER_YAML" "$DRY_RUN" <<'PY'
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

project_dir = Path(sys.argv[1])
tracker_yaml = Path(sys.argv[2])
dry_run = sys.argv[3] == "true"

defaults = {
    "provider": "none",
    "work_ref_format": "GH-{n}",
    "cache_file": ".ai/tracker-cache.json",
    "cache_max_items": 50,
    "cache_statuses": ["open"],
}
data = defaults.copy()
if tracker_yaml.is_file():
    try:
        import yaml
        data.update(yaml.safe_load(tracker_yaml.read_text()) or {})
    except ImportError:
        pass
else:
    data["provider"] = "github"

provider = data.get("provider") or "none"
work_ref_format = data.get("work_ref_format") or "GH-{n}"
cache_file = data.get("cache_file") or ".ai/tracker-cache.json"
max_items = int(data.get("cache_max_items") or 50)
statuses = [s.lower() for s in (data.get("cache_statuses") or ["open"])]
output = project_dir / cache_file

def fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)

if provider == "none":
    fail("tracker provider is none — set provider: github in .ai/tracker.yaml")
if provider in ("linear", "jira"):
    fail(f"provider '{provider}' cache sync not implemented — use paste intake (TRACKER.md)")
if provider != "github":
    fail(f"unknown tracker provider: {provider}")

try:
    subprocess.run(["gh", "auth", "status"], check=True, capture_output=True)
except (FileNotFoundError, subprocess.CalledProcessError):
    fail("gh CLI required and authenticated — run: gh auth login")

try:
    raw = subprocess.check_output(
        [
            "gh", "issue", "list",
            "--state", "open",
            "--limit", str(max_items),
            "--json", "number,title,state,url",
        ],
        text=True,
    )
except subprocess.CalledProcessError:
    fail("gh issue list failed — check repo context and gh auth")

issues = json.loads(raw)
items = []
for issue in issues:
    state = (issue.get("state") or "").lower()
    if statuses and state not in statuses:
        continue
    num = str(issue["number"])
    items.append({
        "work_ref": work_ref_format.replace("{n}", num),
        "external_id": num,
        "title": issue.get("title") or "",
        "status": issue.get("state") or "",
        "url": issue.get("url") or "",
    })

payload = {
    "version": 1,
    "synced_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "provider": provider,
    "items": items,
}

if dry_run:
    print(f"Would write: {output}")
    print(json.dumps(payload, indent=2))
    sys.exit(0)

output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(payload, indent=2) + "\n")
print(f"Wrote {output} ({len(items)} items)")
PY
