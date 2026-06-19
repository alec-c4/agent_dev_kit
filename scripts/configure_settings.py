#!/usr/bin/env python3
"""Apply Agent Dev Kit settings to Cursor and Claude Code tool configs."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
KIT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(SCRIPT_DIR / "lib"))

from apply_tool_settings import (  # noqa: E402
    apply_claude_settings,
    apply_cursor_settings,
    resolve_attribution_flags,
)
from kit_config_paths import resolve_kit_config_path  # noqa: E402
from kit_config_yaml import load_kit_config  # noqa: E402


def load_yaml(path: Path) -> dict[str, Any]:
    return load_kit_config(path)


def load_registry_defaults() -> dict[str, Any]:
    json_path = KIT_DIR / "registry" / "tool-settings.json"
    yaml_path = KIT_DIR / "registry" / "tool-settings.yaml"
    if json_path.is_file():
        import json

        return json.loads(json_path.read_text(encoding="utf-8"))
    if yaml_path.is_file():
        return load_yaml(yaml_path)
    return {}


def parse_bool(value: str) -> bool:
    normalized = value.strip().lower()
    if normalized in {"1", "true", "yes", "on"}:
        return True
    if normalized in {"0", "false", "no", "off"}:
        return False
    raise argparse.ArgumentTypeError(f"expected boolean, got: {value}")


def config_example_path() -> Path:
    return KIT_DIR / "templates" / "config" / "config.yaml.example"


def init_config_from_example(config_path: Path, *, dry_run: bool) -> None:
    example = config_example_path()
    if not example.is_file():
        raise SystemExit(f"Missing template: {example}")
    if config_path.is_file():
        return
    if dry_run:
        print(f"[dry-run] would copy {example} -> {config_path}")
        return
    config_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(example, config_path)
    print(f"initialized {config_path} from kit template")


def load_user_config(config_path: Path, *, fallback_example: bool) -> dict[str, Any]:
    if config_path.is_file():
        return load_yaml(config_path)
    if fallback_example:
        example = config_example_path()
        if example.is_file():
            return load_kit_config(example)
    return {}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help="Kit user settings (default: ~/.config/agent_dev_kit/config.yaml)",
    )
    parser.add_argument(
        "--target",
        choices=("cursor", "claude", "both"),
        default="both",
        help="Which tool configs to update (default: both)",
    )
    parser.add_argument(
        "--cli-config",
        type=Path,
        default=Path.home() / ".cursor" / "cli-config.json",
        help="Cursor CLI config (default: ~/.cursor/cli-config.json)",
    )
    parser.add_argument(
        "--claude-settings",
        type=Path,
        default=Path.home() / ".claude" / "settings.json",
        help="Claude Code settings (default: ~/.claude/settings.json)",
    )
    parser.add_argument(
        "--commits",
        type=parse_bool,
        default=None,
        help="Override commit attribution for selected target(s)",
    )
    parser.add_argument(
        "--prs",
        type=parse_bool,
        default=None,
        help="Override PR attribution for selected target(s)",
    )
    parser.add_argument(
        "--disable-attribution",
        action="store_true",
        help="Disable commit and PR attribution for selected target(s)",
    )
    parser.add_argument(
        "--enable-attribution",
        action="store_true",
        help="Enable commit and PR attribution for selected target(s)",
    )
    parser.add_argument(
        "--init-config",
        action="store_true",
        help="Copy config.yaml.example to XDG path when missing",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print resulting JSON without writing files",
    )
    args = parser.parse_args()

    if args.disable_attribution and args.enable_attribution:
        raise SystemExit("Use only one of --disable-attribution or --enable-attribution")

    config_path = resolve_kit_config_path(
        args.config.expanduser() if args.config else None
    )
    init_requested = args.init_config or args.disable_attribution
    if init_requested:
        init_config_from_example(config_path, dry_run=args.dry_run)

    user_config = load_user_config(
        config_path,
        fallback_example=init_requested and not config_path.is_file(),
    )
    registry = load_registry_defaults()
    kit_cursor = registry.get("cursor") or {}
    kit_claude = registry.get("claude") or {}
    user_cursor = user_config.get("cursor") or {}
    user_claude = user_config.get("claude") or {}

    global_attr = user_config.get("attribution") or {}
    cursor_attr_source = {
        "attribution": {
            **(kit_cursor.get("attribution") or {}),
            **global_attr,
            **(user_cursor.get("attribution") or {}),
        }
    }
    claude_attr_source = {
        "attribution": {
            **(kit_claude.get("attribution") or {}),
            **global_attr,
            **(user_claude.get("attribution") or {}),
        }
    }

    cursor_commits, cursor_prs = resolve_attribution_flags(
        cursor_attr_source,
        commits=args.commits,
        prs=args.prs,
        disable=args.disable_attribution,
        enable=args.enable_attribution,
    )
    claude_commits, claude_prs = resolve_attribution_flags(
        claude_attr_source,
        commits=args.commits,
        prs=args.prs,
        disable=args.disable_attribution,
        enable=args.enable_attribution,
    )

    if args.target in {"cursor", "both"}:
        apply_cursor_settings(
            args.cli_config.expanduser(),
            kit_cursor,
            user_cursor,
            commits=cursor_commits,
            prs=cursor_prs,
            dry_run=args.dry_run,
        )
        if not args.dry_run:
            print(f"wrote Cursor settings → {args.cli_config.expanduser()}")

    if args.target in {"claude", "both"}:
        apply_claude_settings(
            args.claude_settings.expanduser(),
            kit_claude,
            user_claude,
            commits=claude_commits,
            prs=claude_prs,
            dry_run=args.dry_run,
        )
        if not args.dry_run:
            print(f"wrote Claude settings → {args.claude_settings.expanduser()}")

    if not args.dry_run and config_path.is_file():
        print(f"kit config: {config_path}")


if __name__ == "__main__":
    main()
