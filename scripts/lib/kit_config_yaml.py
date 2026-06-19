"""Load kit config.yaml with PyYAML or a minimal fallback parser."""

from __future__ import annotations

from pathlib import Path
from typing import Any


def _line_indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def parse_simple_kit_config(text: str) -> dict[str, Any]:
    config: dict[str, Any] = {}
    section_stack: list[tuple[int, str]] = []

    def current_path() -> list[str]:
        return [key for _, key in section_stack]

    def pop_to_indent(indent: int) -> None:
        while section_stack and section_stack[-1][0] >= indent:
            section_stack.pop()

    def nested_container(path: list[str]) -> dict[str, Any]:
        cursor: dict[str, Any] = config
        for section in path:
            cursor = cursor.setdefault(section, {})
        return cursor

    def set_value(key: str, raw: str) -> None:
        if raw.lower() in {"true", "false"}:
            value: Any = raw.lower() == "true"
        elif raw.startswith("[") and raw.endswith("]"):
            value = []
        else:
            value = raw.strip('"').strip("'")
        nested_container(current_path())[key] = value

    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        indent = _line_indent(line)

        if stripped.startswith("- "):
            item = stripped[2:].strip().strip('"').strip("'")
            path = current_path()
            if not path:
                continue
            parent = nested_container(path[:-1])
            list_key = path[-1]
            items = parent.setdefault(list_key, [])
            if isinstance(items, list):
                items.append(item)
            continue

        if stripped.endswith(":") and not stripped.startswith("-"):
            key = stripped[:-1].strip()
            pop_to_indent(indent)
            section_stack.append((indent, key))
            continue

        if ":" in stripped:
            key, raw = stripped.split(":", 1)
            pop_to_indent(indent)
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
