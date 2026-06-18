# Stack detection

Detection is **declarative** in `registry/stacks.yaml` (signals only). Stack-specific tooling and DoD live in **`skills/stacks/<id>/profile.yaml`**.

## Quick start

```text
# From your application repo (any interactive shell)
path/to/agent_dev_kit/scripts/kit detect-stack --write-profile
cat .claude/stack.profile.json
```

Requires: compiled `profile.json` files (`./scripts/kit compile` from the kit repo).

## Two-step flow

| Step | What | Where |
|------|------|-------|
| 1 | Run detector | `./scripts/kit detect-stack` |
| 2 | Load stack skill + tooling | `skills/stacks/<id>/` |

Read `skills/stack-detection/SKILL.md` and `skills/stack-loader/SKILL.md` for the full protocol.

## Registry (`registry/stacks.yaml`)

- `detection_order` — first match wins
- Per stack: `detect` signals + `stack_skill` pointer (for example `stacks/rails`)
- **No tooling tables here** — those belong in the stack skill profile

## Stack skill profile

`skills/stacks/rails/profile.yaml` (+ compiled `.json`):

- `tooling` — test, lint, security, typecheck commands
- `skills` — required/recommended/conditional pattern skills
- `dod_overlay` — stack-specific Definition of Done items
- `mcp_suggest` — optional MCP hints

Human-oriented context: `skills/stacks/rails/SKILL.md`.

## Profile output

`.claude/stack.profile.json` in the target project:

```json
{
  "primary_stack": "rails",
  "stack_skill": "stacks/rails",
  "tooling": { "test": ["bundle exec rspec", "..."] },
  "skills_to_load": ["stacks/rails", "stack-detection", "testing-universal", "..."],
  "dod_checklist": [ "... universal ...", "... stack overlay ..." ]
}
```

## Adding a new stack

1. Add `skills/stacks/<id>/profile.yaml` + `SKILL.md`
2. Add detection entry in `registry/stacks.yaml` with `stack_skill: stacks/<id>`
3. Run `./scripts/kit compile`
4. Verify: `./scripts/kit detect-stack /path/to/sample-project`

Framework-specific patterns go in **optional pack skills** (for example `rails-core-patterns`), not in guidelines or registry.

See [architecture.md](architecture.md).
