#!/usr/bin/env python3
"""Scan Cursor user rules and build a dedup manifest for Agent Dev Kit."""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_local_overlay(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        import yaml  # type: ignore
    except ImportError as exc:
        raise SystemExit(
            f"PyYAML required to read {path}. Install: pip install pyyaml"
        ) from exc
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    return data if isinstance(data, dict) else {}


def merge_topics(base: dict, overlay: dict) -> dict:
    merged = {k: dict(v) for k, v in base.items()}
    for topic, cfg in (overlay.get("extra_topics") or {}).items():
        merged[topic] = {
            "user_rule_patterns": list(cfg.get("user_rule_patterns") or []),
            "skip_kit_guidelines": list(cfg.get("skip_kit_guidelines") or []),
        }
    return merged


def match_rule(filename: str, patterns: list[str]) -> list[str]:
    matched: list[str] = []
    for pattern in patterns:
        if re.search(pattern, filename):
            matched.append(pattern)
    return matched


def scan_rules(rules_dir: Path, kit_prefix: str) -> list[Path]:
    if not rules_dir.is_dir():
        return []
    files: list[Path] = []
    for path in sorted(rules_dir.glob("*.mdc")):
        if path.name.startswith(kit_prefix):
            continue
        files.append(path)
    return files


def build_manifest(
    registry: dict,
    rules_dirs: list[Path],
    local_overlay: dict,
) -> dict:
    kit_prefix = registry.get("kit_rule_prefix", "kit-")
    always_load = list(registry.get("always_load") or [])
    topics = merge_topics(registry.get("topics") or {}, local_overlay)

    detected: list[dict] = []
    skip_map: dict[str, dict] = {}

    for rules_dir in rules_dirs:
        for rule_path in scan_rules(rules_dir, kit_prefix):
            filename = rule_path.name
            rule_topics: list[str] = []
            for topic_id, cfg in topics.items():
                patterns = cfg.get("user_rule_patterns") or []
                hits = match_rule(filename, patterns)
                if not hits:
                    continue
                rule_topics.append(topic_id)
                for guideline in cfg.get("skip_kit_guidelines") or []:
                    if guideline not in skip_map:
                        skip_map[guideline] = {
                            "path": guideline,
                            "covered_by": filename,
                            "topics": [topic_id],
                        }
                    else:
                        entry = skip_map[guideline]
                        if topic_id not in entry["topics"]:
                            entry["topics"].append(topic_id)
                        if entry["covered_by"] != filename:
                            entry["covered_by"] = f"{entry['covered_by']}, {filename}"

            if rule_topics:
                detected.append(
                    {
                        "file": filename,
                        "path": str(rule_path),
                        "topics": sorted(set(rule_topics)),
                    }
                )

    for guideline in local_overlay.get("additional_skip") or []:
        if guideline not in skip_map:
            skip_map[guideline] = {
                "path": guideline,
                "covered_by": "kit-user-rules.local.yaml",
                "topics": ["local_overlay"],
            }

    skip_list = sorted(skip_map.values(), key=lambda x: x["path"])
    skip_paths = {item["path"] for item in skip_list}

    return {
        "version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "rules_dirs": [str(d) for d in rules_dirs if d.is_dir()],
        "kit_rule_prefix": kit_prefix,
        "detected_user_rules": detected,
        "skip_kit_guidelines": skip_list,
        "always_load_kit_guidelines": always_load,
        "optional_kit_guidelines": [
            path
            for path in (
                "docs/guidelines/TESTING.md",
                "docs/guidelines/COMMITS.md",
                "docs/guidelines/GIT.md",
                "docs/guidelines/CODING.md",
            )
            if path not in skip_paths
        ],
        "policy": (
            "User ~/.cursor/rules win on conflict. "
            "Do not read skip_kit_guidelines unless the human explicitly asks. "
            "Kit-only workflow (SPECS, WORKFLOW, VERIFICATION, REVIEW) is always in scope."
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--registry",
        type=Path,
        default=None,
        help="Path to registry/cursor-user-rules.json",
    )
    parser.add_argument(
        "--rules-dir",
        action="append",
        default=[],
        help="Cursor rules directory (repeatable). Default: ~/.cursor/rules",
    )
    parser.add_argument(
        "--local-overlay",
        type=Path,
        default=Path.home() / ".cursor" / "kit-user-rules.local.yaml",
        help="Optional user overlay for extra patterns",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path.home() / ".cursor" / "kit-user-rules.manifest.json",
        help="Manifest output path",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print manifest to stdout instead of writing",
    )
    args = parser.parse_args()

    kit_dir = Path(__file__).resolve().parent.parent
    registry_path = args.registry or (kit_dir / "registry" / "cursor-user-rules.json")
    if not registry_path.is_file():
        raise SystemExit(
            f"Missing {registry_path}. Run: bash scripts/compile_registry.sh"
        )

    rules_dirs = [Path(p).expanduser() for p in args.rules_dir]
    if not rules_dirs:
        rules_dirs = [Path.home() / ".cursor" / "rules"]

    registry = load_json(registry_path)
    overlay = load_local_overlay(args.local_overlay.expanduser())
    manifest = build_manifest(registry, rules_dirs, overlay)

    payload = json.dumps(manifest, indent=2) + "\n"
    if args.dry_run:
        print(payload, end="")
        return

    out = args.output.expanduser()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(payload, encoding="utf-8")
    print(f"wrote {out}")
    print(
        f"  user rules: {len(manifest['detected_user_rules'])}, "
        f"skip kit guidelines: {len(manifest['skip_kit_guidelines'])}"
    )


if __name__ == "__main__":
    main()
