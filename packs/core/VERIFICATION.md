# Core pack verification (v1.0)

Pack: `core` — 16 skills (3 universal + 13 stack profiles).

**Process:** [docs/skills-review.md](../../docs/skills-review.md)

**Automated:** `./scripts/kit validate-skills --pack=core`

| Skill | Agent | Agent notes | Human |
|-------|-------|-------------|-------|
| stack-detection | OK | Matches [stack-detection.md](../../docs/stack-detection.md), `registry/stacks.yaml`; defers tooling to stack skills | OK |
| stack-loader | OK | Profile field table matches `profile.yaml` schema used by detect-stack; lazy load aligns with architecture | OK |
| testing-universal | OK | Aligns with [TESTING.md](../../docs/guidelines/TESTING.md); defers runners to profile.tooling | OK |
| stacks/django | OK | Thin router; source of truth `profile.yaml`; matches stack-agnostic rule | OK |
| stacks/elixir | OK | Same pattern as django | OK |
| stacks/fastapi | OK | Same pattern | OK |
| stacks/flask | OK | Same pattern | OK |
| stacks/go | OK | Same pattern | OK |
| stacks/nextjs | OK | Same pattern | OK |
| stacks/node | OK | Same pattern | OK |
| stacks/nuxt | OK | Same pattern | OK |
| stacks/python | OK | Same pattern | OK |
| stacks/rails | OK | profile.yaml tooling (rspec, rubocop, brakeman) matches Rails conventions | OK |
| stacks/rust | OK | Thin router + profile | OK |
| stacks/svelte | OK | Thin router + profile | OK |
| stacks/sveltekit | OK | Thin router + profile | OK |

## Agent batch summary

- **Universal skills** route to guidelines and `detect-stack.sh` — no framework commands embedded.
- **Stack skills** are intentionally thin: `SKILL.md` + `profile.yaml` + `profile.json`; deep patterns belong in future pattern packs (stash), not core.
- **No broken doc links** in universal skills; stack skills link only to local `profile.yaml`.

## Human sign-off (pack)

- [x] I reviewed at least 3 skills full-text: _______________
- [x] I ran `./scripts/kit validate-skills --pack=core` — PASS
- [x] I ran `./scripts/kit deploy-skills --pack=core --dry-run` — paths look correct
- [x] **Pack approved for merge:** YYYY-MM-DD — 2026-06-18
