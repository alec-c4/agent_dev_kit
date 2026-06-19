#!/usr/bin/env bash
# compile_registry.sh — Build registry/*.json from *.yaml (for stdlib-only detect-stack)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REG="$KIT_DIR/registry"

compile_one() {
  local name="$1"
  local yaml="$REG/${name}.yaml"
  local json="$REG/${name}.json"
  [[ -f "$yaml" ]] || return 0
  if command -v ruby &>/dev/null; then
    ruby -ryaml -rjson -e "
      File.write('$json', JSON.pretty_generate(YAML.load_file('$yaml')))
      puts 'wrote $json'
    "
  elif python3 -c "import yaml" 2>/dev/null; then
    python3 -c "
import json, yaml
from pathlib import Path
data = yaml.safe_load(Path('$yaml').read_text())
Path('$json').write_text(json.dumps(data, indent=2) + chr(10))
print('wrote $json')
"
  else
    echo "ERROR: need ruby or python3+PyYAML" >&2
    exit 1
  fi
}

for name in stacks topics dod cursor-user-rules tool-targets tool-settings; do
  compile_one "$name"
done

# Stack skill profiles (stdlib-friendly detect_stack.py)
for yaml in "$KIT_DIR"/skills/stacks/*/profile.yaml; do
  [[ -f "$yaml" ]] || continue
  json="${yaml%.yaml}.json"
  if command -v ruby &>/dev/null; then
    ruby -ryaml -rjson -e "
      File.write('$json', JSON.pretty_generate(YAML.load_file('$yaml')))
      puts 'wrote $json'
    "
  elif python3 -c "import yaml" 2>/dev/null; then
    python3 -c "
import json, yaml
from pathlib import Path
p = Path('$yaml')
Path('$json').write_text(json.dumps(yaml.safe_load(p.read_text()), indent=2) + chr(10))
print('wrote $json')
"
  fi
done

# Pack manifests (official + community; skip template)
for yaml in "$KIT_DIR"/packs/*/manifest.yaml "$KIT_DIR"/packs/community/*/manifest.yaml; do
  [[ -f "$yaml" ]] || continue
  [[ "$yaml" == *"/_template/"* ]] && continue
  json="${yaml%.yaml}.json"
  if command -v ruby &>/dev/null; then
    ruby -ryaml -rjson -e "
      File.write('$json', JSON.pretty_generate(YAML.load_file('$yaml')))
      puts 'wrote $json'
    "
  elif python3 -c "import yaml" 2>/dev/null; then
    python3 -c "
import json, yaml
from pathlib import Path
p = Path('$yaml')
Path('$json').write_text(json.dumps(yaml.safe_load(p.read_text()), indent=2) + chr(10))
print('wrote $json')
"
  fi
done
