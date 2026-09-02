#!/usr/bin/env bash
# validate-registry.sh — CI gate for registry, packs, skills, and topics
# Exit 0 = pass, 1 = failures found
#
# Usage:
#   bash scripts/validate-registry.sh           # full validation
#   bash scripts/validate-registry.sh --phase=1 # registry JSON and stack profiles only

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

# ── tool settings configure smoke test ────────────────────────────────────────
CONFIGURE_CMD=()
if command -v bun &>/dev/null && [[ -f "$KIT_DIR/packages/kit-runtime/src/cli/configure.ts" ]]; then
  CONFIGURE_CMD=(bun "$KIT_DIR/packages/kit-runtime/src/cli/configure.ts")
elif [[ -f "$KIT_DIR/scripts/configure_settings.py" ]]; then
  CONFIGURE_CMD=(python3 "$KIT_DIR/scripts/configure_settings.py")
fi

if [[ ${#CONFIGURE_CMD[@]} -eq 0 ]]; then
  err "missing configure (Bun cli/configure.ts or scripts/configure_settings.py)"
elif [[ ! -f "$KIT_DIR/registry/tool-settings.json" ]]; then
  err "missing registry/tool-settings.json — run: bash scripts/compile_registry.sh"
elif [[ ! -f "$KIT_DIR/templates/config/config.yaml.example" ]]; then
  err "missing templates/config/config.yaml.example"
else
  tmp_cli="$(mktemp)"
  tmp_claude="$(mktemp)"
  if "${CONFIGURE_CMD[@]}" \
    --cli-config "$tmp_cli" \
    --claude-settings "$tmp_claude" \
    --target=both >/dev/null 2>&1 \
    && jq -e '
      .attribution.attributeCommitsToAgent == false
      and (.permissions.allow | index("Shell(git)"))
    ' "$tmp_cli" >/dev/null \
    && jq -e '
      .attribution.commit == ""
      and (.includeCoAuthoredBy | not)
      and (.permissions.allow | index("Bash(git *)"))
    ' "$tmp_claude" >/dev/null; then
    ok "configure tool settings cursor + claude"
  else
    err "configure tool settings failed"
  fi
  rm -f "$tmp_cli" "$tmp_claude"
fi

# ── documentation i18n ───────────────────────────────────────────────────────
if [[ -x "$KIT_DIR/scripts/validate-docs-i18n.sh" ]]; then
  if bash "$KIT_DIR/scripts/validate-docs-i18n.sh"; then
    ok "docs i18n (locales registry + translations)"
  else
    err "docs i18n validation failed"
  fi
elif [[ ! -f "$KIT_DIR/registry/locales.json" ]]; then
  err "missing registry/locales.json — run: bash scripts/compile_registry.sh"
fi

if [[ "$PHASE" == "1" ]]; then
  echo "Registry mode — registry JSON + stack skill profiles only"
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
  elif [[ ! -f "$KIT_DIR/templates/cursor/rules/kit-comprehension.mdc" ]]; then
    err "missing templates/cursor/rules/kit-comprehension.mdc"
  elif [[ ! -f "$KIT_DIR/templates/cursor/rules/kit-process-language.mdc" ]]; then
    err "missing templates/cursor/rules/kit-process-language.mdc"
  else
    ok "cursor user-rules dedup (sync script + kit-user-rules.mdc)"
    ok "cursor global comprehension gate (kit-comprehension.mdc)"
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
    err "missing agents/ personas"
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

  for name in stacks topics dod cursor-user-rules tool-targets tool-settings locales; do
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
  # Strict by default: an orphan skill never reaches a user, because
  # deploy-skills only walks pack manifests. Set VALIDATE_ORPHANS_STRICT=0
  # to downgrade to a warning while a skill is still being drafted.
  if [[ "${VALIDATE_ORPHANS_STRICT:-1}" == "0" ]]; then
    warn "orphan skill directory (not in packs or registry): skills/$name — add to a pack or remove"
  else
    err "orphan skill directory (not in packs or registry): skills/$name — add to a pack or remove"
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
  deny_msg="$(printf '%s' '{"tool_input":{"command":"rm -rf /tmp/foo"}}' | bash "$KIT_DIR/hooks/block-dangerous.sh" 2>&1 >/dev/null || true)"
  # The three lines must be specific to the blocked command — kit_block's
  # generic fallbacks mean the call site passed only `what`.
  if ! echo "$deny_msg" | grep -q '^Why:' || ! echo "$deny_msg" | grep -q '^Next:'; then
    err "hook smoke: deny text missing Why/Next"
  elif echo "$deny_msg" | grep -q '^Why: This command is not allowed\.$'; then
    err "hook smoke: deny text uses the generic Why — pass a reason to kit_block"
  elif echo "$deny_msg" | grep -q '^Next: Use a safer command or confirm with the human\.$'; then
    err "hook smoke: deny text uses the generic Next — pass a remedy to kit_block"
  else
    ok "hook smoke: deny text has specific Why and Next"
  fi
  if printf '%s' '{"tool_input":{"command":"git status"}}' | bash "$KIT_DIR/hooks/block-dangerous.sh" >/dev/null 2>&1; then
    ok "hook smoke: block-dangerous allows git status"
  else
    err "block-dangerous.sh blocked benign git status"
  fi
fi

# ── detect-stack dry run on fixtures ──────────────────────────────────────────
# Prefer Bun detect-stack when available
kit_detect_stack() {
  local cwd="$1"
  if command -v bun &>/dev/null && [[ -f "$KIT_DIR/packages/kit-runtime/src/cli/detect-stack.ts" ]]; then
    bun "$KIT_DIR/packages/kit-runtime/src/cli/detect-stack.ts" --cwd "$cwd" --kit-dir "$KIT_DIR"
  else
    python3 "$KIT_DIR/scripts/detect_stack.py" --cwd "$cwd" --kit-dir "$KIT_DIR"
  fi
}

# fixture dir : expected primary_stack
DETECT_FIXTURES=(
  "minimal-rails:rails"
  "minimal-elixir:elixir"
  "minimal-swift:swift"
  "minimal-kotlin:kotlin"
  "minimal-react-native:react-native"
  "minimal-flutter:flutter"
  "minimal-node:node"
  "minimal-fastapi:fastapi"
  "minimal-django:django"
  "minimal-flask:flask"
  "minimal-python:python"
  "minimal-tauri:tauri"
)

for entry in "${DETECT_FIXTURES[@]}"; do
  fixture_name="${entry%%:*}"
  expected="${entry##*:}"
  fixture_dir="$KIT_DIR/scripts/fixtures/$fixture_name"
  [[ -d "$fixture_dir" ]] || continue
  actual="$(kit_detect_stack "$fixture_dir" 2>/dev/null | jq -r '.primary_stack // "null"')"
  if [[ "$actual" == "$expected" ]]; then
    ok "detect_stack fixture $expected"
  else
    err "detect_stack fixture $fixture_name: expected $expected, got $actual"
  fi
done

# ── shell scripts parse (a nested heredoc broke `kit intake` silently) ───────
for script in "$KIT_DIR"/scripts/kit "$KIT_DIR"/scripts/*.sh "$KIT_DIR"/scripts/lib/*.sh \
  "$KIT_DIR"/hooks/*.sh "$KIT_DIR"/hooks/lib/*.sh "$KIT_DIR"/hooks/cursor/*.sh; do
  [[ -f "$script" ]] || continue
  bash -n "$script" 2>/dev/null || err "shell syntax error: ${script#"$KIT_DIR"/}"
done
ok "shell scripts parse (bash -n)"

# ── intake smoke test ────────────────────────────────────────────────────────
INTAKE_TMP="$(mktemp -d)"
mkdir -p "$INTAKE_TMP/.ai"
printf 'provider: github\n' > "$INTAKE_TMP/.ai/tracker.yaml"
if (cd "$INTAKE_TMP" && printf 'Smoke title\n\nBody.\n' \
      | bash "$KIT_DIR/scripts/intake-work-item.sh" GH-1 --paste >/dev/null 2>&1) \
   && [[ -f "$INTAKE_TMP/.ai/work/GH-1-analysis.md" ]]; then
  ok "intake writes .ai/work/{ref}-analysis.md"
else
  err "intake did not write .ai/work/GH-1-analysis.md"
fi
rm -rf "$INTAKE_TMP"

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
