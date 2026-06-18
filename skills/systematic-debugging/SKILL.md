---
name: systematic-debugging
description: Structured debugging before guessing — reproduce, isolate, bisect, verify fix. Use when bugs are unclear or regressions need root cause.
user-invokable: false
---

# Systematic debugging

Use when a bug is reported but root cause is unknown. Complements [fix](../fix/SKILL.md) workflow — run **before** large code changes.

## Protocol

1. **Reproduce** — minimal steps; capture input, env, stack profile commands.
2. **Isolate** — narrow to file, test, or layer (DB, API, UI).
3. **Hypothesis** — one at a time; prefer tests over printf debugging.
4. **Fix** — smallest change; add regression test mapping to spec AC.
5. **Verify** — stack profile test + lint; document in analysis if non-obvious.

## Stack commands

Read `profile.yaml` from detected stack — do not hardcode runners.

## Do not

- Shotgun refactor without reproduction.
- Skip regression test for fixed bugs.
