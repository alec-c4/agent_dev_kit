"""Load kit config.yaml with PyYAML or a minimal fallback parser."""

from __future__ import annotations

from pathlib import Path
from typing import Any


def parse_simple_kit_config(text: str) -> dict[str, Any]:
    config: dict[str, Any] = {}
    section_stack: list[str] = []

    def set_value(key: str, raw: str) -> None:
        if raw.lower() in {"true", "false"}:
            value: Any = raw.lower() == "true"
        elif raw.startswith("[") and raw.endswith("]"):
            value = []
        else:
            value = raw.strip('"').strip("'")
        cursor: dict[str, Any] = config
        for section in section_stack:
            cursor = cursor.setdefault(section, {})
        cursor[key] = value

    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.endswith(":") and not stripped.startswith("-"):
            key = stripped[:-1]
            if section_stack and section_stack[-1] == key:
                section_stack.pop()
            else:
                section_stack.append(key)
            continue
        if stripped.startswith("- "):
            item = stripped[2:].strip().strip('"').strip("'")
            cursor: dict[str, Any] = config
            for section in section_stack[:-1]:
                cursor = cursor.setdefault(section, {})
            list_key = section_stack[-1] if section_stack else "items"
            cursor.setdefault(list_key, [])
            if isinstance(cursor[list_key], list):
                cursor[list_key].append(item)
            continue
        if ":" in stripped:
            key, raw = stripped.split(":", 1)
            set_value(key.strip(), raw.strip())

    return config


def load_kit_config(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    text = path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore

        data = yaml.safe_load(text) or {}
        return data if isinstance(data, dict) else {}
    except ImportError:
        return parse_simple_kit_config(text)
