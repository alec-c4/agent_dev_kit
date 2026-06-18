#!/usr/bin/env python3
"""Detect project stack from registry + stack skill profiles; emit JSON profile."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def kit_dir_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def _load_data(kit: Path, name: str) -> dict:
    """Load registry/topics from JSON (stdlib) or YAML (requires PyYAML)."""
    json_path = kit / "registry" / f"{name}.json"
    yaml_path = kit / "registry" / f"{name}.yaml"

    if json_path.is_file():
        return json.loads(json_path.read_text(encoding="utf-8"))

    if yaml_path.is_file():
        try:
            import yaml
        except ImportError:
            print(
                json.dumps(
                    {
                        "error": (
                            f"Install PyYAML or add registry/{name}.json: "
                            "pip install pyyaml"
                        )
                    }
                ),
                file=sys.stderr,
            )
            sys.exit(1)
        with yaml_path.open(encoding="utf-8") as f:
            return yaml.safe_load(f)

    raise FileNotFoundError(f"No registry/{name}.json or .yaml in {kit}")


def load_yaml_path(path: Path) -> dict:
    if path.suffix == ".json":
        return json.loads(path.read_text(encoding="utf-8"))
    try:
        import yaml
    except ImportError:
        json_path = path.with_suffix(".json")
        if json_path.is_file():
            return json.loads(json_path.read_text(encoding="utf-8"))
        raise
    with path.open(encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def load_registry(kit: Path) -> dict:
    return _load_data(kit, "stacks")


def load_topics(kit: Path) -> dict:
    return _load_data(kit, "topics")


def load_dod(kit: Path) -> dict:
    try:
        return _load_data(kit, "dod")
    except FileNotFoundError:
        return {"universal": []}


def load_stack_profile(kit: Path, stack_skill: str) -> dict:
    base = kit / "skills" / stack_skill
    json_path = base / "profile.json"
    yaml_path = base / "profile.yaml"
    if json_path.is_file():
        return json.loads(json_path.read_text(encoding="utf-8"))
    if yaml_path.is_file():
        return load_yaml_path(yaml_path)
    raise FileNotFoundError(f"Missing stack profile: {yaml_path}")


def resolve_dod_checklist(profile: dict, dod: dict) -> list[dict]:
    items = list(dod.get("universal") or [])
    items.extend(profile.get("dod_overlay") or [])
    return items


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def package_deps(cwd: Path) -> dict:
    pkg = cwd / "package.json"
    if not pkg.is_file():
        return {}
    try:
        data = json.loads(read_text(pkg))
        deps: dict = {}
        deps.update(data.get("dependencies") or {})
        deps.update(data.get("devDependencies") or {})
        return deps
    except json.JSONDecodeError:
        return {}


def gemfile_has_gem(gemfile: str, gem_name: str) -> bool:
    escaped = re.escape(gem_name).replace(r"\ ", r"[\s_\-]*")
    return bool(
        re.search(rf"gem\s+['\"]{escaped}['\"]", gemfile, re.I)
        or re.search(rf"gem\s+['\"]{gem_name.replace('_', '-')}['\"]", gemfile, re.I)
    )


def matches_stack(stack_id: str, spec: dict, cwd: Path, stacks: dict) -> bool:
    detect = spec.get("detect") or {}
    files = detect.get("files") or []
    any_files = detect.get("any_files") or []
    any_glob = detect.get("any_glob") or []

    if files and not all((cwd / f).is_file() for f in files):
        return False

    if any_files or any_glob:
        matched = any((cwd / f).is_file() for f in any_files)
        if any_glob:
            matched = matched or any(
                p.is_file() for g in any_glob for p in cwd.glob(g)
            )
        if not files and not matched:
            return False

    if dep := detect.get("package_dep"):
        if dep not in package_deps(cwd):
            return False

    if exclude := detect.get("exclude_package_dep"):
        if exclude in package_deps(cwd):
            return False

    if match := detect.get("content_match"):
        combined = ""
        for name in files:
            combined += read_text(cwd / name) + "\n"
        if not files:
            for name in any_files:
                p = cwd / name
                if p.is_file():
                    combined += read_text(p) + "\n"
            for pattern in any_glob:
                for p in cwd.glob(pattern):
                    if p.is_file():
                        combined += read_text(p) + "\n"
        manage = cwd / "manage.py"
        if manage.is_file():
            combined += read_text(manage)
        if match.lower() not in combined.lower():
            return False

    if gem := detect.get("gem"):
        gemfile = read_text(cwd / "Gemfile")
        if not gemfile_has_gem(gemfile, gem):
            return False

    if stack_id == "python":
        for other in ("fastapi", "django", "flask"):
            other_spec = stacks.get(other)
            if other_spec and matches_stack(other, other_spec, cwd, stacks):
                return False

    if stack_id == "node":
        for other in ("nextjs", "nuxt", "sveltekit", "svelte", "astro", "react-native"):
            other_spec = stacks.get(other)
            if other_spec and matches_stack(other, other_spec, cwd, stacks):
                return False

    return True


def resolve_skills(profile: dict, cwd: Path) -> list[str]:
    skills_cfg = profile.get("skills") or {}
    out: list[str] = []
    seen: set[str] = set()

    def add(name: str) -> None:
        if name and name not in seen:
            seen.add(name)
            out.append(name)

    stack_skill = profile.get("stack_skill")
    if stack_skill:
        add(stack_skill)

    for key in ("required", "recommended"):
        for s in skills_cfg.get(key) or []:
            add(s)

    if (cwd / "spec").is_dir():
        for s in skills_cfg.get("if_spec_dir") or []:
            add(s)
    elif (cwd / "test").is_dir():
        for s in skills_cfg.get("if_test_dir") or []:
            add(s)

    gemfile = read_text(cwd / "Gemfile")
    for gem, skill_list in (skills_cfg.get("if_gem") or {}).items():
        if gemfile_has_gem(gemfile, gem):
            for s in skill_list:
                add(s)

    deps = package_deps(cwd)
    for dep, skill_list in (skills_cfg.get("if_package_dep") or {}).items():
        if dep in deps:
            for s in skill_list:
                add(s)

    for rel, rule in (skills_cfg.get("if_file") or {}).items():
        path = cwd / rel
        if not path.is_file():
            continue
        if match := rule.get("content_match"):
            if match.lower() not in read_text(path).lower():
                continue
        for s in rule.get("skills") or []:
            add(s)

    return out


def resolve_topic_files(primary: str, topics: dict) -> dict[str, str]:
    result: dict[str, str] = {}
    for topic_id, cfg in (topics.get("topics") or {}).items():
        rel = (cfg.get("stack_files") or {}).get(primary)
        if rel:
            result[topic_id] = f"skills/{rel}"
    return result


def detect(cwd: Path, kit: Path) -> dict:
    registry = load_registry(kit)
    topics = load_topics(kit)
    dod = load_dod(kit)
    order = registry.get("detection_order") or []
    stacks = registry.get("stacks") or {}

    primary = None
    stack_entry = None
    for stack_id in order:
        spec = stacks.get(stack_id)
        if spec and matches_stack(stack_id, spec, cwd, stacks):
            primary = stack_id
            stack_entry = spec
            break

    if not primary or not stack_entry:
        return {
            "version": 1,
            "detected_at": datetime.now(timezone.utc).isoformat(),
            "cwd": str(cwd.resolve()),
            "primary_stack": None,
            "error": (
                "No stack matched. Declare stack in project CLAUDE.md or "
                "add detection in registry/stacks.yaml"
            ),
        }

    stack_skill = stack_entry.get("stack_skill")
    if not stack_skill:
        return {
            "version": 1,
            "detected_at": datetime.now(timezone.utc).isoformat(),
            "cwd": str(cwd.resolve()),
            "primary_stack": primary,
            "error": f"Stack {primary} missing stack_skill in registry/stacks.yaml",
        }

    try:
        profile = load_stack_profile(kit, stack_skill)
    except FileNotFoundError as exc:
        return {
            "version": 1,
            "detected_at": datetime.now(timezone.utc).isoformat(),
            "cwd": str(cwd.resolve()),
            "primary_stack": primary,
            "error": str(exc),
        }

    profile = dict(profile)
    profile["stack_skill"] = stack_skill

    tooling = dict(profile.get("tooling") or {})
    optional = tooling.pop("optional", None)
    if optional:
        tooling["optional"] = optional

    return {
        "version": 1,
        "detected_at": datetime.now(timezone.utc).isoformat(),
        "cwd": str(cwd.resolve()),
        "primary_stack": primary,
        "stack_skill": stack_skill,
        "label": profile.get("label"),
        "language": profile.get("language"),
        "framework": profile.get("framework"),
        "tooling": tooling,
        "universal_tooling": registry.get("universal_tooling") or {},
        "skills_to_load": resolve_skills(profile, cwd),
        "topic_files": resolve_topic_files(primary, topics),
        "mcp_suggest": profile.get("mcp_suggest") or [],
        "dod_checklist": resolve_dod_checklist(profile, dod),
        "stack_profile_path": str((kit / "skills" / stack_skill / "profile.yaml").resolve()),
        "dod_registry_path": str((kit / "registry" / "dod.yaml").resolve()),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Detect stack and emit JSON profile")
    parser.add_argument("--cwd", default=".", help="Project directory to scan")
    parser.add_argument("--kit-dir", help="Path to Agent Dev Kit repository")
    parser.add_argument(
        "--write-profile",
        action="store_true",
        help="Write .claude/stack.profile.json in cwd",
    )
    args = parser.parse_args()

    cwd = Path(args.cwd).resolve()
    kit = Path(args.kit_dir).resolve() if args.kit_dir else kit_dir_from_script()

    if not (kit / "registry" / "stacks.json").is_file() and not (
        kit / "registry" / "stacks.yaml"
    ).is_file():
        print(json.dumps({"error": f"Registry not found in {kit / 'registry'}"}))
        return 1

    profile = detect(cwd, kit)
    print(json.dumps(profile, indent=2))

    if args.write_profile and profile.get("primary_stack"):
        out_dir = cwd / ".claude"
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / "stack.profile.json"
        out_path.write_text(json.dumps(profile, indent=2) + "\n", encoding="utf-8")
        print(f"Wrote {out_path}", file=sys.stderr)

    return 0 if profile.get("primary_stack") else 1


if __name__ == "__main__":
    sys.exit(main())
