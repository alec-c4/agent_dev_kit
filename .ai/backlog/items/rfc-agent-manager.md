# RFC: Multi-agent manager (backlog)

**Status:** idea  
**spec_language:** en  
**Created:** 2026-07-31

## Problem

Large milestones may need one agent session per `work_ref`, with a coordinator that answers cross-task questions using other specs/plans or escalates to the human.

## Non-goals for now

- No runtime message bus in the DX status Bun epic.
- No automatic agent swarm.

## Proposed maturity (later)

1. File inbox: `.ai/work/{ref}-inbox.md` + orchestrator skill.
2. Optional tool-specific subagent wiring (Cursor Task / Claude agents).
3. Only then consider a daemon/manager — after (1) proves value.

## Decision needed before scheduling

Portability across Cursor / Claude / Codex without a kit-owned agent runtime.
