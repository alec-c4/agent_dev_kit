#!/usr/bin/env bash
# smoke-commands.sh — run every `kit` command against a throwaway HOME
#
# `kit intake` shipped broken for a while because nothing ever ran it. `bash -n`
# in validate-registry.sh catches syntax errors; this catches the rest — a
# command that parses, starts, and then fails on its first real argument.
#
# Everything writes inside one temp sandbox: HOME, XDG_CONFIG_HOME, and the
# project directory. Commands run for real, not with --dry-run, wherever doing
# so is safe.
#
# Usage:
#   bash scripts/smoke-commands.sh            # all commands
#   bash scripts/smoke-commands.sh --verbose  # show command output
#   bash scripts/smoke-commands.sh --keep     # leave the sandbox for inspection
#
# Env:
#   KIT_SMOKE_OFFLINE=1   skip the checks that need network (verify-docs)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
KIT="$KIT_DIR/scripts/kit"

VERBOSE=false
KEEP=false
for arg in "$@"; do
  case "$arg" in
    --verbose | -v) VERBOSE=true ;;
    --keep) KEEP=true ;;
    --help | -h)
      sed -n '/^# Usage:/,/^$/p' "$0" | sed -e 's/^# //' -e 's/^#$//'
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

PASS=0
FAIL=0
SKIP=0

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/kit-smoke.XXXXXX")"
SANDBOX_HOME="$SANDBOX/home"
PROJECT="$SANDBOX/project"
OUT="$SANDBOX/last-output.txt"
BOARD_PORT="${KIT_SMOKE_BOARD_PORT:-18787}"

cleanup() {
  if $KEEP; then
    echo "sandbox kept: $SANDBOX"
    return
  fi
  # The board is a background Bun process with its own cache under $HOME; it can
  # still be flushing when the first rm walks the tree.
  rm -rf "$SANDBOX" 2>/dev/null || { sleep 1; rm -rf "$SANDBOX"; }
}
trap cleanup EXIT

mkdir -p "$SANDBOX_HOME/.config" "$PROJECT/.ai"
printf "source 'https://rubygems.org'\ngem 'rails'\n" >"$PROJECT/Gemfile"
printf 'provider: github\n' >"$PROJECT/.ai/tracker.yaml"

# The point of the sandbox: a command that reaches for the real ~/.claude or
# ~/.config lands here instead.
export HOME="$SANDBOX_HOME"
export XDG_CONFIG_HOME="$SANDBOX_HOME/.config"
export KIT_BOARD_PORT="$BOARD_PORT"

pass() {
  PASS=$((PASS + 1))
  echo "  ok: $*"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "FAIL: $*" >&2
  if [[ -s "$OUT" ]]; then
    sed -e 's/^/      | /' "$OUT" | tail -12 >&2
  fi
}

skip() {
  SKIP=$((SKIP + 1))
  echo "  skip: $*"
}

# kit_run <expected-exit> <label> -- <args...>
# Runs `kit` from the sandbox project and checks the exit code. Output lands in
# $OUT so a later assertion (or a failure report) can read it.
kit_run() {
  local expected="$1" label="$2"
  shift 2
  [[ "${1:-}" == "--" ]] && shift
  local rc=0
  (cd "$PROJECT" && "$KIT" "$@") >"$OUT" 2>&1 || rc=$?
  $VERBOSE && sed -e 's/^/      | /' "$OUT"
  if [[ "$rc" -ne "$expected" ]]; then
    fail "$label — expected exit $expected, got $rc"
    return 1
  fi
  return 0
}

# assert_file <path> <label>
assert_file() {
  if [[ -e "$1" ]]; then
    pass "$2"
  else
    fail "$2 — missing ${1#"$SANDBOX"/}"
  fi
}

# assert_out <regex> <label>
assert_out() {
  if grep -Eq "$1" "$OUT"; then
    pass "$2"
  else
    fail "$2 — output did not match /$1/"
  fi
}

# `kit deploy-hooks` used to chmod +x the kit's own hooks/lib/, leaving a mode
# change behind on every run. Snapshot the checkout so any such write shows up.
TREE_BEFORE="$SANDBOX/tree-before.txt"
TREE_AFTER="$SANDBOX/tree-after.txt"
git -C "$KIT_DIR" status --porcelain >"$TREE_BEFORE" 2>/dev/null || : >"$TREE_BEFORE"

echo "kit command smoke tests"
echo "  kit:     $KIT"
echo "  sandbox: $SANDBOX"
echo ""

# ── dispatcher ───────────────────────────────────────────────────────────────
kit_run 0 "kit help" -- help && assert_out '^Usage:' "kit help prints usage"
kit_run 1 "kit <unknown>" -- definitely-not-a-command &&
  assert_out 'unknown kit command' "unknown command exits 1 with a reason"

# `kit run` must not reach outside scripts/ — the guard is the whole point.
kit_run 0 "kit run detect-shell.sh" -- run detect-shell.sh &&
  pass "kit run executes a kit script"
kit_run 1 "kit run ../evil.sh" -- run ../evil.sh &&
  assert_out 'not a path' "kit run rejects a path argument"
kit_run 1 "kit run missing.sh" -- run definitely-missing.sh &&
  assert_out 'no such kit script' "kit run rejects an unknown script"

# ── introspection ────────────────────────────────────────────────────────────
kit_run 0 "kit shell-info" -- shell-info --json &&
  { jq -e . "$OUT" >/dev/null 2>&1 && pass "shell-info --json emits JSON" ||
    fail "shell-info --json did not emit JSON"; }

# ── registry ─────────────────────────────────────────────────────────────────
# compile writes into the kit checkout, so verify it is a no-op on a clean tree
# rather than a source of drift.
REGISTRY_WAS_CLEAN=false
if git -C "$KIT_DIR" diff --quiet -- registry/ 2>/dev/null; then
  REGISTRY_WAS_CLEAN=true
fi
if kit_run 0 "kit compile" -- compile; then
  if jq -e . "$KIT_DIR/registry/stacks.json" >/dev/null 2>&1; then
    pass "compile writes parseable registry/stacks.json"
  else
    fail "compile left registry/stacks.json unparseable"
  fi
  if ! $REGISTRY_WAS_CLEAN; then
    skip "compile idempotence (registry/ was already dirty)"
  elif git -C "$KIT_DIR" diff --quiet -- registry/; then
    pass "compile is idempotent on a clean tree"
  else
    fail "compile changed registry/ — the committed JSON is stale or compile is nondeterministic"
  fi
fi

kit_run 0 "kit validate --phase=1" -- validate --phase=1 &&
  pass "validate --phase=1"
kit_run 0 "kit validate-skills" -- validate-skills --pack=core &&
  pass "validate-skills --pack=core"

HANDOFF_EXAMPLE="$KIT_DIR/docs/examples/work/GH-58-handoff.example.md"
if [[ -f "$HANDOFF_EXAMPLE" ]]; then
  kit_run 0 "kit validate-handoff" -- validate-handoff --file="$HANDOFF_EXAMPLE" --tier=standard &&
    pass "validate-handoff on the shipped example"
else
  skip "validate-handoff (no example fixture)"
fi

# ── install and deploy (real writes, sandboxed HOME) ──────────────────────────
if kit_run 0 "kit install --target=claude" -- install --target=claude; then
  assert_file "$SANDBOX_HOME/.claude/skills/feature/SKILL.md" "install --target=claude deploys skills"
  assert_file "$SANDBOX_HOME/.claude/AGENTS.md" "install --target=claude deploys AGENTS.md"
fi

kit_run 0 "kit deploy-skills" -- deploy-skills --pack=core --scope=project &&
  assert_file "$PROJECT/.agents/skills/feature/SKILL.md" "deploy-skills --scope=project"

kit_run 0 "kit deploy-workflows" -- deploy-workflows --scope=project &&
  assert_file "$PROJECT/.agents/workflows/feature.md" "deploy-workflows --scope=project"

kit_run 0 "kit deploy-hooks" -- deploy-hooks --scope=project --target=claude &&
  assert_file "$PROJECT/.claude/hooks/block-dangerous.sh" "deploy-hooks --scope=project"

kit_run 0 "kit configure --dry-run" -- configure --target=claude --dry-run &&
  { jq -e . "$OUT" >/dev/null 2>&1 && pass "configure --dry-run emits JSON" ||
    fail "configure --dry-run did not emit JSON"; }

kit_run 0 "kit sync-rules --dry-run" -- sync-rules --dry-run &&
  { jq -e . "$OUT" >/dev/null 2>&1 && pass "sync-rules --dry-run emits JSON" ||
    fail "sync-rules --dry-run did not emit JSON"; }

# ── stack detection ──────────────────────────────────────────────────────────
if kit_run 0 "kit detect-stack" -- detect-stack .; then
  detected="$(jq -r '.primary_stack // .stack_id // empty' "$OUT" 2>/dev/null)"
  if [[ "$detected" == "rails" ]]; then
    pass "detect-stack identifies the Gemfile fixture as rails"
  else
    fail "detect-stack: expected rails, got '${detected:-<none>}'"
  fi
fi
kit_run 0 "kit detect-stack --write-profile" -- detect-stack --write-profile . &&
  assert_file "$PROJECT/.claude/stack.profile.json" "detect-stack --write-profile"

# ── project registry and status ──────────────────────────────────────────────
kit_run 0 "kit register" -- register . &&
  assert_file "$XDG_CONFIG_HOME/agent-dev-kit/projects.yaml" "register writes projects.yaml"
kit_run 0 "kit status" -- status --project . &&
  pass "status on a registered project"
kit_run 0 "kit status --json" -- status --project . --json &&
  { jq -e . "$OUT" >/dev/null 2>&1 && pass "status --json emits JSON" ||
    fail "status --json did not emit JSON"; }

# ── intake ───────────────────────────────────────────────────────────────────
if (cd "$PROJECT" && printf 'Smoke title\n\nBody.\n' | "$KIT" intake GH-42 --paste) >"$OUT" 2>&1; then
  assert_file "$PROJECT/.ai/work/GH-42-analysis.md" "intake --paste writes the analysis file"
else
  fail "kit intake GH-42 --paste"
fi

# sync-tracker needs an authenticated gh; a clean refusal is a pass, a crash is not.
if kit_run 0 "kit sync-tracker --dry-run" -- sync-tracker --dry-run 2>/dev/null; then
  pass "sync-tracker --dry-run"
elif grep -Eqi 'gh (cli|auth)' "$OUT"; then
  FAIL=$((FAIL - 1)) # kit_run already counted the nonzero exit
  skip "sync-tracker --dry-run (gh not authenticated — refused cleanly)"
fi

# ── findings ledger ──────────────────────────────────────────────────────────
kit_run 0 "kit findings append" -- findings append \
  --work-ref GH-42 --fingerprint smoke-probe --stage verify \
  --severity block --summary "smoke finding" --evidence "smoke run" &&
  pass "findings append"
kit_run 0 "kit findings list" -- findings list GH-42 &&
  assert_out 'smoke-probe' "findings list shows the appended row"
kit_run 1 "kit findings gate (open)" -- findings gate --work-ref GH-42 &&
  pass "findings gate blocks while a finding is open"
kit_run 0 "kit findings close" -- findings close F-1 --work-ref GH-42 --run "true" &&
  pass "findings close with a passing sensor"
kit_run 0 "kit findings gate (closed)" -- findings gate --work-ref GH-42 &&
  pass "findings gate passes once closed"

# ── lessons ──────────────────────────────────────────────────────────────────
kit_run 0 "kit lessons propose" -- lessons propose \
  --fingerprint smoke-fp --guide "do the thing" --sensor "true" --stack rails &&
  pass "lessons propose"
# A pending lesson is invisible to the session view by design, but must be
# discoverable — `ack` needs the id.
kit_run 0 "kit lessons list --all" -- lessons list --all &&
  assert_out 'smoke-fp' "lessons list --all shows the pending lesson"
kit_run 0 "kit lessons ack" -- lessons ack L-1 &&
  pass "lessons ack"
kit_run 0 "kit lessons list" -- lessons list &&
  assert_out 'smoke-fp' "lessons list shows the lesson once ack'd"

# ── pattern check ────────────────────────────────────────────────────────────
kit_run 0 "kit check-patterns" -- check-patterns &&
  pass "check-patterns on a clean project"
kit_run 0 "kit check-patterns --list-sensors" -- check-patterns --list-sensors &&
  pass "check-patterns --list-sensors"

# ── doc freshness (network) ──────────────────────────────────────────────────
if [[ "${KIT_SMOKE_OFFLINE:-}" == "1" ]]; then
  skip "verify-docs (KIT_SMOKE_OFFLINE=1)"
elif kit_run 0 "kit verify-docs" -- verify-docs --skill fastapi-patterns --no-links --json; then
  if jq -e . "$OUT" >/dev/null 2>&1; then
    pass "verify-docs --json emits JSON"
  else
    fail "verify-docs --json did not emit JSON"
  fi
fi

# ── board ────────────────────────────────────────────────────────────────────
BOARD_LOG="$SANDBOX/board.log"
(cd "$PROJECT" && "$KIT" board) >"$BOARD_LOG" 2>&1 &
BOARD_PID=$!
board_ok=false
for _ in $(seq 1 20); do
  if curl -fsS "http://127.0.0.1:$BOARD_PORT/" -o "$SANDBOX/board.html" 2>/dev/null; then
    board_ok=true
    break
  fi
  kill -0 "$BOARD_PID" 2>/dev/null || break
  sleep 0.5
done
kill "$BOARD_PID" 2>/dev/null || true
wait "$BOARD_PID" 2>/dev/null || true
if $board_ok && grep -q '<!DOCTYPE html>' "$SANDBOX/board.html"; then
  pass "board serves HTML on 127.0.0.1:$BOARD_PORT"
else
  cp "$BOARD_LOG" "$OUT" 2>/dev/null || true
  fail "board did not serve HTML on 127.0.0.1:$BOARD_PORT"
fi

# ── the kit checkout is not a scratch directory ──────────────────────────────
if git -C "$KIT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$KIT_DIR" status --porcelain >"$TREE_AFTER" 2>/dev/null || : >"$TREE_AFTER"
  if diff -q "$TREE_BEFORE" "$TREE_AFTER" >/dev/null; then
    pass "running every command left the kit checkout unchanged"
  else
    diff "$TREE_BEFORE" "$TREE_AFTER" >"$OUT" 2>&1 || true
    fail "a kit command wrote into its own checkout"
  fi
else
  skip "checkout-unchanged (not a git repo)"
fi

# ── result ───────────────────────────────────────────────────────────────────
echo ""
if [[ $FAIL -gt 0 ]]; then
  echo "FAILED: $FAIL failure(s), $PASS passed, $SKIP skipped"
  exit 1
fi
echo "PASSED: $PASS check(s), $SKIP skipped"
exit 0
