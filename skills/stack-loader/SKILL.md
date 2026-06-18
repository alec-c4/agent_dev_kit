---
name: stack-loader
description: Resolve tooling and skills from stack profile — registry detection plus skills/stacks/*/profile.yaml.
user-invokable: false
disable-model-invocation: true
---

# Stack loader

Use the **stack profile** as the source of truth for commands and skills. Guidelines and entry points stay stack-agnostic.

## Step 1: Obtain profile

**Preferred:**

```bash
bash scripts/detect-stack.sh --write-profile
```

**Cached:** `.claude/stack.profile.json`

**Manual:** read `skills/stacks/<id>/profile.yaml` after identifying the stack.

## Step 2: Profile fields

| Field | Use |
|-------|-----|
| `primary_stack` | Stack id (`rails`, `nextjs`, …) |
| `stack_skill` | Path to stack skill (`stacks/rails`) — read `SKILL.md` + `profile.yaml` |
| `label` | Human-readable name |
| `tooling.test` | Test commands — try in order |
| `tooling.lint` | Linter commands |
| `tooling.security` | Security scanners |
| `tooling.deps_audit` | Dependency audits |
| `tooling.typecheck` | Type checkers |
| `tooling.optional` | Run only if installed |
| `universal_tooling.context` | Git context for review |
| `skills_to_load` | Skills to read on demand |
| `topic_files` | Cross-topic stack files (security, llm, …) |
| `mcp_suggest` | MCPs when available |
| `dod_checklist` | Universal DoD + stack overlay from profile |

## Step 3: Run tooling

1. Use `profile.tooling.<category>` in order.
2. First success wins; report all failures if none pass.
3. Skip optional tools when binaries are missing.

## Step 4: Load skills (lazy)

Read only what the task needs:

```
skills/<name>/SKILL.md
skills/stacks/<id>/SKILL.md
```

Pattern and framework depth skills (for example `rails-core-patterns`) ship in packs — load from `skills_to_load`.

## Step 5: Report

```
Stack: [label] (id: [primary_stack], skill: [stack_skill])
Tests: [command used]
```
