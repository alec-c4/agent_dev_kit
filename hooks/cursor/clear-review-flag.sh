#!/usr/bin/env bash
export KIT_HOOK_TARGET=cursor
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/clear-review-flag.sh"
