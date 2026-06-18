#!/usr/bin/env bash
# validate-registry.sh — CI gate for registry, packs, skills, and topics
# Exit 0 = pass, 1 = failures found
#
# Usage:
#   bash scripts/validate-registry.sh           # full validation
#   bash scripts/validate-registry.sh --phase=1 # registry JSON only (Phase 1 kit)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ERRORS=0
WARNINGS=0
PHASE="full"

for arg in "$@"; do
  case "$arg" in
    --phase=1) PHASE="1" ;;
    --help|-h)
      echo "Usage: $0 [--phase=1]"
      exit 0
      ;;
  esac
done

err() { echo "ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }
warn() { echo "WARN: $*" >&2; WARNINGS=$((WARNINGS + 1)); }
ok() { echo "  ok: $*"; }

echo "Validating Agent Dev Kit at $KIT_DIR"
echo ""

# ── jq required ───────────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  err "jq is required"
  exit 1
fi

# ── Registry JSON present ─────────────────────────────────────────────────────
for name in stacks topics dod; do
  if [[ ! -f "$KIT_DIR/registry/${name}.json" ]]; then
    err "missing registry/${name}.json — run: bash scripts/compile_registry.sh"
  else
    ok "registry/${name}.json"
  fi
done

if [[ "$PHASE" == "1" ]]; then
  echo "Phase 1 mode — registry + stack skill profiles only"
  echo ""

  if [[ -f "$KIT_DIR/registry/stacks.json" ]]; then
    while IFS= read -r sid; do
      [[ -z "$sid" ]] && continue
      skill=$(jq -r ".stacks[\"$sid\"].stack_skill // empty" "$KIT_DIR/registry/stacks.json")
      if [[ -z "$skill" ]]; then
        err "stack $sid missing stack_skill in registry/stacks.yaml"
        continue
      fi
      if [[ ! -f "$KIT_DIR/skills/$skill/profile.yaml" ]]; then
        err "stack $sid → missing skills/$skill/profile.yaml"
      elif [[ ! -f "$KIT_DIR/skills/$skill/profile.json" ]]; then
        warn "skills/$skill/profile.json missing — run: bash scripts/compile_registry.sh"
      else
        ok "stack profile $skill"
      fi
      if [[ ! -f "$KIT_DIR/skills/$skill/SKILL.md" ]]; then
        err "stack $sid → missing skills/$skill/SKILL.md"
      fi
    done < <(jq -r '.stacks | keys[]' "$KIT_DIR/registry/stacks.json")
  fi

  for skill in $(jq -r '.skills[] | select(startswith("stacks/") | not)' "$KIT_DIR/packs/core/manifest.json" 2>/dev/null); do
    [[ -z "$skill" ]] && continue
    if [[ ! -f "$KIT_DIR/skills/$skill/SKILL.md" ]]; then
      err "missing core skill: skills/$skill/SKILL.md"
    else
      ok "core skill $skill"
    fi
  done

  if [[ ! -f "$KIT_DIR/registry/cursor-user-rules.json" ]]; then
    err "missing registry/cursor-user-rules.json — run: bash scripts/compile_registry.sh"
  else
    ok "registry/cursor-user-rules.json"
  fi

  if [[ ! -f "$KIT_DIR/scripts/sync-cursor-user-rules.sh" ]]; then
    err "missing scripts/sync-cursor-user-rules.sh"
  elif [[ ! -f "$KIT_DIR/templates/cursor/rules/kit-user-rules.mdc" ]]; then
    err "missing templates/cursor/rules/kit-user-rules.mdc"
  else
    ok "cursor user-rules dedup (sync script + kit-user-rules.mdc)"
  fi

  if [[ ! -f "$KIT_DIR/docs/guidelines/TRACKER.md" ]]; then
    err "missing docs/guidelines/TRACKER.md"
  else
    ok "docs/guidelines/TRACKER.md"
  fi

  if [[ ! -f "$KIT_DIR/docs/guidelines/COMPREHENSION.md" ]]; then
    err "missing docs/guidelines/COMPREHENSION.md"
  elif [[ ! -f "$KIT_DIR/docs/examples/work/GH-58-handoff.example.md" ]]; then
    err "missing docs/examples/work/GH-58-handoff.example.md"
  else
    ok "human comprehension gate (COMPREHENSION.md + handoff example)"
  fi

  if [[ ! -f "$KIT_DIR/packs/core/manifest.json" ]]; then
    err "missing packs/core/manifest.json — run: bash scripts/compile_registry.sh"
  elif [[ ! -f "$KIT_DIR/scripts/deploy-skills.sh" ]]; then
    err "missing scripts/deploy-skills.sh"
  elif [[ ! -f "$KIT_DIR/scripts/validate-skills.sh" ]]; then
    err "missing scripts/validate-skills.sh"
  elif [[ ! -f "$KIT_DIR/scripts/deploy-workflows.sh" ]]; then
    err "missing scripts/deploy-workflows.sh"
  elif [[ ! -f "$KIT_DIR/scripts/intake-work-item.sh" ]]; then
    err "missing scripts/intake-work-item.sh"
  elif [[ ! -f "$KIT_DIR/scripts/sync-tracker-cache.sh" ]]; then
    err "missing scripts/sync-tracker-cache.sh"
  elif [[ ! -f "$KIT_DIR/scripts/validate-handoff.sh" ]]; then
    err "missing scripts/validate-handoff.sh"
  elif [[ ! -f "$KIT_DIR/scripts/deploy-hooks.sh" ]]; then
    err "missing scripts/deploy-hooks.sh"
  elif [[ ! -f "$KIT_DIR/hooks/block-dangerous.sh" ]]; then
    err "missing hooks/block-dangerous.sh"
  elif [[ ! -f "$KIT_DIR/skills/comprehension-check/SKILL.md" ]]; then
    err "missing skills/comprehension-check/SKILL.md"
  else
    ok "core skills pack (packs/core + deploy + intake + sync-tracker + validate-handoff)"
  fi

  if [[ ! -f "$KIT_DIR/packs/patterns/manifest.json" ]]; then
    warn "missing packs/patterns/manifest.json — run: bash scripts/compile_registry.sh"
  else
    ok "patterns skills pack (packs/patterns)"
  fi

  if [[ ! -f "$KIT_DIR/packs/topics/manifest.json" ]]; then
    warn "missing packs/topics/manifest.json — run: bash scripts/compile_registry.sh"
  else
    ok "topics skills pack (packs/topics)"
  fi

  for sp in rails node python go elixir devops astro tauri swift kotlin react-native flutter; do
    if [[ ! -f "$KIT_DIR/packs/$sp/manifest.json" ]]; then
      warn "missing packs/$sp/manifest.json — run: bash scripts/compile_registry.sh"
    else
      ok "stack pack (packs/$sp)"
    fi
  done

  if [[ ! -d "$KIT_DIR/agents" ]] || [[ ! -f "$KIT_DIR/agents/developer.md" ]]; then
    err "missing agents/ personas (Phase 2 P6)"
  else
    ok "Claude Code agents (agents/*.md)"
  fi

  if [[ ! -f "$KIT_DIR/scripts/kit" ]]; then
    err "missing scripts/kit CLI wrapper"
  elif [[ ! -f "$KIT_DIR/docs/shell-commands.md" ]]; then
    err "missing docs/shell-commands.md"
  else
    ok "shell-agnostic kit CLI (scripts/kit + docs/shell-commands.md)"
  fi

  if [[ ! -f "$KIT_DIR/registry/tool-targets.json" ]]; then
    err "missing registry/tool-targets.json — run: bash scripts/compile_registry.sh"
  elif [[ ! -f "$KIT_DIR/docs/tool-adapters.md" ]]; then
    err "missing docs/tool-adapters.md"
  elif [[ ! -f "$KIT_DIR/GEMINI.md" ]]; then
    err "missing GEMINI.md (Antigravity adapter)"
  elif [[ ! -f "$KIT_DIR/templates/project-agents/skills-README.md" ]]; then
    err "missing templates/project-agents/ scaffold"
  else
    ok "tool adapters (tool-targets + GEMINI.md + tool-adapters.md)"
  fi

  for name in stacks topics dod cursor-user-rules tool-targets; do
    yaml="$KIT_DIR/registry/${name}.yaml"
    json="$KIT_DIR/registry/${name}.json"
    [[ -f "$yaml" && -f "$json" ]] || continue
    if [[ "$yaml" -nt "$json" ]]; then
      warn "registry/${name}.yaml is newer than .json — run: bash scripts/compile_registry.sh"
    fi
  done
  echo ""
  if [[ $ERRORS -gt 0 ]]; then
    echo "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
    exit 1
  fi
  echo "PASSED phase 1 ($WARNINGS warning(s))"
  exit 0
fi

# ── stacks: detection_order ↔ stacks keys ─────────────────────────────────────
if [[ -f "$KIT_DIR/registry/stacks.json" ]]; then
  while IFS= read -r sid; do
    [[ -z "$sid" ]] && continue
    if ! jq -e ".stacks[\"$sid\"]" "$KIT_DIR/registry/stacks.json" >/dev/null; then
      err "detection_order references unknown stack: $sid"
    fi
  done < <(jq -r '.detection_order[]' "$KIT_DIR/registry/stacks.json")

  while IFS= read -r sid; do
    [[ -z "$sid" ]] && continue
    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      if [[ ! -d "$KIT_DIR/skills/$skill" ]]; then
        err "stack $sid references missing skill: skills/$skill"
      fi
    done < <(jq -r ".stacks[\"$sid\"].skills | (.required // []) + (.recommended // []) + (.if_spec_dir // []) + (.if_test_dir // []) | .[]" "$KIT_DIR/registry/stacks.json" 2>/dev/null)
    # if_gem skills
    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      if [[ ! -d "$KIT_DIR/skills/$skill" ]]; then
        err "stack $sid if_gem references missing skill: skills/$skill"
      fi
    done < <(jq -r ".stacks[\"$sid\"].skills.if_gem // {} | .[] | .[]" "$KIT_DIR/registry/stacks.json" 2>/dev/null)
  done < <(jq -r '.stacks | keys[]' "$KIT_DIR/registry/stacks.json")
fi

# ── topics: stack files exist ─────────────────────────────────────────────────
if [[ -f "$KIT_DIR/registry/topics.json" ]]; then
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ ! -f "$KIT_DIR/skills/$path" ]]; then
      err "topics references missing file: skills/$path"
    fi
  done < <(jq -r '.topics[].stack_files | .[]' "$KIT_DIR/registry/topics.json")
fi

# ── packs: manifests and skills ─────────────────────────────────────────────────
for manifest in "$KIT_DIR"/packs/*/manifest.json "$KIT_DIR"/packs/community/*/manifest.json; do
  [[ -f "$manifest" ]] || continue
  [[ "$manifest" == *"/_template/"* ]] && continue
  pack=$(jq -r '.id' "$manifest")
  ok "pack $pack"

  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    if [[ ! -f "$KIT_DIR/packs/$dep/manifest.json" ]]; then
      err "pack $pack depends_on missing pack: $dep"
    fi
  done < <(jq -r '.depends_on[]? // empty' "$manifest")

  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    if [[ ! -d "$KIT_DIR/skills/$skill" ]]; then
      err "pack $pack references missing skill: skills/$skill"
    fi
    if [[ ! -f "$KIT_DIR/skills/$skill/SKILL.md" ]]; then
      err "pack $pack skill missing SKILL.md: skills/$skill"
    fi
  done < <(jq -r '.skills[]' "$manifest")
done

# ── Empty skill directories ───────────────────────────────────────────────────
for skill_dir in "$KIT_DIR"/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  name=$(basename "$skill_dir")
  [[ "$name" == "stacks" ]] && continue
  if [[ ! -f "$skill_dir/SKILL.md" ]]; then
    err "empty skill directory (no SKILL.md): skills/$name"
  fi
done

# ── Orphan top-level skill dirs (not in any pack or registry) ─────────────────
PACKED_SKILLS=$(mktemp)
REGISTRY_SKILLS=$(mktemp)
trap 'rm -f "$PACKED_SKILLS" "$REGISTRY_SKILLS"' EXIT
for m in "$KIT_DIR"/packs/*/manifest.json "$KIT_DIR"/packs/community/*/manifest.json; do
  [[ -f "$m" ]] || continue
  [[ "$m" == *"/_template/"* ]] && continue
  jq -r '.skills[]' "$m" >> "$PACKED_SKILLS"
done
jq -r '
  .stacks[] | .skills |
  (.required // []) + (.recommended // []) + (.if_spec_dir // []) + (.if_test_dir // []) + [(.if_gem // {} | .[] | .[])]
  | .[]
' "$KIT_DIR/registry/stacks.json" >> "$REGISTRY_SKILLS" 2>/dev/null
jq -r '.topics[].skill' "$KIT_DIR/registry/topics.json" >> "$REGISTRY_SKILLS" 2>/dev/null
for skill_dir in "$KIT_DIR"/skills/*/; do
  name=$(basename "$skill_dir")
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  # inertia/* nested skills are loaded via parent inertia/SKILL.md
  if grep -qxF "$name" "$PACKED_SKILLS" 2>/dev/null || grep -qxF "$name" "$REGISTRY_SKILLS" 2>/dev/null; then
    continue
  fi
  if [[ "${VALIDATE_ORPHANS_STRICT:-}" == "1" ]]; then
    err "orphan skill directory (not in packs or registry): skills/$name"
  else
    warn "orphan skill directory (not in packs or registry): skills/$name — add to a pack or remove"
  fi
done

# ── agents: required frontmatter ──────────────────────────────────────────────
for agent in "$KIT_DIR"/agents/*.md; do
  [[ -f "$agent" ]] || continue
  [[ "$(basename "$agent")" == "README.md" ]] && continue
  if ! grep -q '^name:' "$agent"; then
    err "agent missing name: $(basename "$agent")"
  fi
  if ! grep -q '^description:' "$agent"; then
    err "agent missing description: $(basename "$agent")"
  fi
done
ok "agents frontmatter"

# ── hooks: exist and executable ───────────────────────────────────────────────
for hook in "$KIT_DIR"/hooks/*.sh; do
  [[ -f "$hook" ]] || continue
  if [[ ! -x "$hook" ]]; then
    warn "hook not executable: $(basename "$hook") — run chmod +x"
  fi
  if ! bash -n "$hook" 2>/dev/null; then
    err "hook syntax error: $(basename "$hook")"
  fi
done
ok "hooks"

# ── hook smoke tests ────────────────────────────────────────────────────────────
if [[ -f "$KIT_DIR/hooks/block-dangerous.sh" ]]; then
  if printf '%s' '{"tool_input":{"command":"rm -rf /tmp/foo"}}' | bash "$KIT_DIR/hooks/block-dangerous.sh" >/dev/null 2>&1; then
    err "block-dangerous.sh should block rm -rf"
  else
    ok "hook smoke: block-dangerous rejects rm -rf"
  fi
  if printf '%s' '{"tool_input":{"command":"git status"}}' | bash "$KIT_DIR/hooks/block-dangerous.sh" >/dev/null 2>&1; then
    ok "hook smoke: block-dangerous allows git status"
  else
    err "block-dangerous.sh blocked benign git status"
  fi
fi

# ── detect-stack dry run on fixtures ──────────────────────────────────────────
FIXTURE_RAILS="$KIT_DIR/scripts/fixtures/minimal-rails"
if [[ -d "$FIXTURE_RAILS" ]]; then
  if python3 "$KIT_DIR/scripts/detect_stack.py" --cwd "$FIXTURE_RAILS" --kit-dir "$KIT_DIR" 2>/dev/null | jq -e '.primary_stack == "rails"' >/dev/null; then
    ok "detect_stack fixture rails"
  else
    err "detect_stack fixture did not detect rails"
  fi
fi

FIXTURE_ELIXIR="$KIT_DIR/scripts/fixtures/minimal-elixir"
if [[ -d "$FIXTURE_ELIXIR" ]]; then
  if python3 "$KIT_DIR/scripts/detect_stack.py" --cwd "$FIXTURE_ELIXIR" --kit-dir "$KIT_DIR" 2>/dev/null | jq -e '.primary_stack == "elixir"' >/dev/null; then
    ok "detect_stack fixture elixir"
  else
    err "detect_stack fixture did not detect elixir"
  fi
fi

FIXTURE_SWIFT="$KIT_DIR/scripts/fixtures/minimal-swift"
if [[ -d "$FIXTURE_SWIFT" ]]; then
  if python3 "$KIT_DIR/scripts/detect_stack.py" --cwd "$FIXTURE_SWIFT" --kit-dir "$KIT_DIR" 2>/dev/null | jq -e '.primary_stack == "swift"' >/dev/null; then
    ok "detect_stack fixture swift"
  else
    err "detect_stack fixture did not detect swift"
  fi
fi

FIXTURE_KOTLIN="$KIT_DIR/scripts/fixtures/minimal-kotlin"
if [[ -d "$FIXTURE_KOTLIN" ]]; then
  if python3 "$KIT_DIR/scripts/detect_stack.py" --cwd "$FIXTURE_KOTLIN" --kit-dir "$KIT_DIR" 2>/dev/null | jq -e '.primary_stack == "kotlin"' >/dev/null; then
    ok "detect_stack fixture kotlin"
  else
    err "detect_stack fixture did not detect kotlin"
  fi
fi

FIXTURE_REACT_NATIVE="$KIT_DIR/scripts/fixtures/minimal-react-native"
if [[ -d "$FIXTURE_REACT_NATIVE" ]]; then
  if python3 "$KIT_DIR/scripts/detect_stack.py" --cwd "$FIXTURE_REACT_NATIVE" --kit-dir "$KIT_DIR" 2>/dev/null | jq -e '.primary_stack == "react-native"' >/dev/null; then
    ok "detect_stack fixture react-native"
  else
    err "detect_stack fixture did not detect react-native"
  fi
fi

FIXTURE_FLUTTER="$KIT_DIR/scripts/fixtures/minimal-flutter"
if [[ -d "$FIXTURE_FLUTTER" ]]; then
  if python3 "$KIT_DIR/scripts/detect_stack.py" --cwd "$FIXTURE_FLUTTER" --kit-dir "$KIT_DIR" 2>/dev/null | jq -e '.primary_stack == "flutter"' >/dev/null; then
    ok "detect_stack fixture flutter"
  else
    err "detect_stack fixture did not detect flutter"
  fi
fi

# ── validate-handoff fixture ──────────────────────────────────────────────────
HANDOFF_EXAMPLE="$KIT_DIR/docs/examples/work/GH-58-handoff.example.md"
if [[ -f "$HANDOFF_EXAMPLE" ]]; then
  if bash "$KIT_DIR/scripts/validate-handoff.sh" --file="$HANDOFF_EXAMPLE" --tier=standard >/dev/null 2>&1; then
    ok "validate-handoff fixture (GH-58-handoff.example.md)"
  else
    err "validate-handoff fixture failed on GH-58-handoff.example.md"
  fi
fi

# ── YAML vs JSON staleness ────────────────────────────────────────────────────
for name in stacks topics dod; do
  yaml="$KIT_DIR/registry/${name}.yaml"
  json="$KIT_DIR/registry/${name}.json"
  [[ -f "$yaml" && -f "$json" ]] || continue
  if [[ "$yaml" -nt "$json" ]]; then
    if [[ "${VALIDATE_STRICT:-}" == "1" ]]; then
      err "registry/${name}.yaml is newer than .json — run: bash scripts/compile_registry.sh"
    else
      warn "registry/${name}.yaml is newer than .json — run: bash scripts/compile_registry.sh"
    fi
  fi
done

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
fi
echo "PASSED ($WARNINGS warning(s))"
exit 0
