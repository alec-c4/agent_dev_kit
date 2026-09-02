"""XDG config paths for Agent Dev Kit user settings.

Two directory spellings shipped: ``agent_dev_kit`` (tool settings) and
``agent-dev-kit`` (projects and lessons). The hyphenated form is canonical;
the underscored one is still read so an existing install keeps working.
Mirrors ``packages/kit-runtime/src/kit-paths.ts``.
"""

from __future__ import annotations

import os
from pathlib import Path

CANONICAL = "agent-dev-kit"
LEGACY = "agent_dev_kit"


def _config_home() -> Path:
    xdg = os.environ.get("XDG_CONFIG_HOME")
    if xdg:
        return Path(xdg).expanduser()
    return Path.home() / ".config"


def kit_config_dir() -> Path:
    """Canonical directory for new files."""
    return _config_home() / CANONICAL


def kit_config_path(name: str) -> Path:
    """Path to read for *name*, preferring canonical over the legacy directory."""
    canonical = _config_home() / CANONICAL / name
    if canonical.exists():
        return canonical
    legacy = _config_home() / LEGACY / name
    if legacy.exists():
        return legacy
    return canonical


def default_kit_config_path() -> Path:
    return kit_config_path("config.yaml")


def resolve_kit_config_path(explicit: Path | None = None) -> Path:
    if explicit is not None:
        return explicit.expanduser()
    return default_kit_config_path()
