# Analysis: adhoc-dx-status-bun

**Work ref:** adhoc-dx-status-bun  
**Spec key:** dx-status-bun  
**Milestone:** m1-runtime-board

## Problem

Kit DX lacks realtime visibility into pipeline stages across projects; multiple runtimes (bash/ruby/python); no global project registry.

## Affected areas

- `scripts/kit`, `scripts/detect-stack.sh`, `packages/kit-runtime/`
- CI validate.yml
- docs WORKFLOW / shell-commands
- `.ai/` taxonomy

## Notes

Checkpoint tag `checkpoint/pre-dx-status-bun`. Audit in `adhoc-dx-status-bun-audit.md`.
