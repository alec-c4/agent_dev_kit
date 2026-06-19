"""Merge kit tool settings into Cursor cli-config and Claude Code settings."""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Any


PERMISSION_LIST_KEYS = ("allow", "deny", "ask")
CURSOR_SCALAR_KEYS = ("approvalMode", "maxMode")
CLAUDE_SCALAR_KEYS = ("includeGitInstructions", "defaultMode")


def load_json(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        return {}
    data = json.loads(text)
    if not isinstance(data, dict):
        raise SystemExit(f"Invalid JSON object in {path}")
    return data


def write_json(path: Path, payload: dict[str, Any], *, dry_run: bool) -> None:
    rendered = json.dumps(payload, indent=2) + "\n"
    if dry_run:
        print(rendered, end="")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(rendered, encoding="utf-8")


def merge_list_union(*lists: list[Any] | None) -> list[Any]:
    seen: set[Any] = set()
    merged: list[Any] = []
    for lst in lists:
        for item in lst or []:
            if item in seen:
                continue
            seen.add(item)
            merged.append(item)
    return merged


def merge_permissions(
    base: dict[str, Any] | None, *overlays: dict[str, Any] | None
) -> dict[str, Any]:
    result = dict(base or {})
    for overlay in overlays:
        if not overlay:
            continue
        for key in PERMISSION_LIST_KEYS:
            if key not in overlay:
                continue
            result[key] = merge_list_union(result.get(key), overlay.get(key))
    return result


def merge_section(
    base: dict[str, Any],
    *overlays: dict[str, Any] | None,
    scalar_keys: tuple[str, ...] = (),
) -> dict[str, Any]:
    result = deepcopy(base)
    for overlay in overlays:
        if not overlay:
            continue
        if "permissions" in overlay:
            result["permissions"] = merge_permissions(
                result.get("permissions"), overlay.get("permissions")
            )
        for key in scalar_keys:
            if key in overlay:
                result[key] = overlay[key]
    return result


def attribution_to_cursor(commits: bool, prs: bool) -> dict[str, bool]:
    return {
        "attributeCommitsToAgent": commits,
        "attributePRsToAgent": prs,
    }


def attribution_to_claude(commits: bool, prs: bool) -> dict[str, str] | None:
    if commits and prs:
        return None
    payload: dict[str, str] = {}
    if not commits:
        payload["commit"] = ""
    if not prs:
        payload["pr"] = ""
    return payload


def resolve_attribution_flags(
    section: dict[str, Any],
    *,
    commits: bool | None,
    prs: bool | None,
    disable: bool,
    enable: bool,
) -> tuple[bool, bool]:
    if disable:
        return False, False
    if enable:
        return True, True

    attr = section.get("attribution") or {}
    resolved_commits = commits if commits is not None else attr.get("commits")
    resolved_prs = prs if prs is not None else attr.get("prs")
    if isinstance(resolved_commits, bool) and isinstance(resolved_prs, bool):
        return resolved_commits, resolved_prs
    if resolved_commits is None and resolved_prs is None and "enabled" in attr:
        enabled = bool(attr["enabled"])
        return enabled, enabled
    return (
        bool(resolved_commits) if isinstance(resolved_commits, bool) else True,
        bool(resolved_prs) if isinstance(resolved_prs, bool) else True,
    )


def build_cursor_payload(
    existing: dict[str, Any],
    kit_defaults: dict[str, Any],
    user_section: dict[str, Any],
    *,
    commits: bool,
    prs: bool,
) -> dict[str, Any]:
    payload = deepcopy(existing)
    if "version" not in payload:
        payload["version"] = 1

    merged = merge_section(
        {},
        kit_defaults,
        user_section,
        scalar_keys=CURSOR_SCALAR_KEYS,
    )
    if merged.get("permissions"):
        payload["permissions"] = merge_permissions(
            payload.get("permissions"), merged.get("permissions")
        )
    for key in CURSOR_SCALAR_KEYS:
        if key in merged:
            payload[key] = merged[key]

    payload["attribution"] = attribution_to_cursor(commits, prs)
    return payload


def build_claude_payload(
    existing: dict[str, Any],
    kit_defaults: dict[str, Any],
    user_section: dict[str, Any],
    *,
    commits: bool,
    prs: bool,
) -> dict[str, Any]:
    payload = deepcopy(existing)
    payload.pop("includeCoAuthoredBy", None)

    merged = merge_section(
        {},
        kit_defaults,
        user_section,
        scalar_keys=CLAUDE_SCALAR_KEYS,
    )
    if merged.get("permissions"):
        payload["permissions"] = merge_permissions(
            payload.get("permissions"), merged.get("permissions")
        )
    for key in CLAUDE_SCALAR_KEYS:
        if key in merged:
            payload[key] = merged[key]

    claude_attr = attribution_to_claude(commits, prs)
    if claude_attr is None:
        payload.pop("attribution", None)
    else:
        payload["attribution"] = claude_attr
    return payload


def apply_cursor_settings(
    cli_path: Path,
    kit_defaults: dict[str, Any],
    user_section: dict[str, Any],
    *,
    commits: bool,
    prs: bool,
    dry_run: bool,
) -> dict[str, Any]:
    existing = load_json(cli_path)
    payload = build_cursor_payload(
        existing, kit_defaults, user_section, commits=commits, prs=prs
    )
    write_json(cli_path, payload, dry_run=dry_run)
    return payload


def apply_claude_settings(
    settings_path: Path,
    kit_defaults: dict[str, Any],
    user_section: dict[str, Any],
    *,
    commits: bool,
    prs: bool,
    dry_run: bool,
) -> dict[str, Any]:
    existing = load_json(settings_path)
    payload = build_claude_payload(
        existing, kit_defaults, user_section, commits=commits, prs=prs
    )
    write_json(settings_path, payload, dry_run=dry_run)
    return payload
