---
name: stack-detection
description: Detect the project technology stack before any task. Run detect-stack.sh; do not guess tooling from memory.
user-invokable: false
---

# Stack detection

The kit is **stack-agnostic**. Detection signals live in `registry/stacks.yaml`. Everything stack-specific (tooling, DoD overlays, patterns) lives in **`skills/stacks/<id>/`**.

## Protocol

1. Run the detector (preferred):

```bash
bash scripts/detect-stack.sh --write-profile
# or: bash "$HOME/.claude/scripts/detect-stack.sh" --write-profile"
```

2. Read `.claude/stack.profile.json` in the target project.

3. Load the stack skill from `stack_skill` in the profile (for example `skills/stacks/rails/SKILL.md` and `profile.yaml`).

## Override

If the project declares an explicit stack in `CLAUDE.md` or `AGENTS.md`, trust it — then still run the detector to resolve tooling commands.

## Registry

- `registry/stacks.yaml` — file signals and `stack_skill` pointers only
- `skills/stacks/*/profile.yaml` — test/lint/security commands, skill routing, DoD overlay

## Monorepos

Run detection per package directory:

```bash
bash scripts/detect-stack.sh --write-profile path/to/package
```

## No match

If detection fails, ask the human to declare the stack or add a new entry under `skills/stacks/` and `registry/stacks.yaml`.

Do not embed stack-specific commands in guidelines or entry-point files — add or extend a stack skill instead.
