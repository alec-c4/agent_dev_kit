"""XDG config paths for Agent Dev Kit user settings."""

from __future__ import annotations

import os
from pathlib import Path


def kit_config_dir() -> Path:
    xdg = os.environ.get("XDG_CONFIG_HOME")
    if xdg:
        return Path(xdg).expanduser() / "agent_dev_kit"
    return Path.home() / ".config" / "agent_dev_kit"


def default_kit_config_path() -> Path:
    return kit_config_dir() / "config.yaml"


def resolve_kit_config_path(explicit: Path | None = None) -> Path:
    if explicit is not None:
        return explicit.expanduser()
    return default_kit_config_path()
