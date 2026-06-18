# Core pack verification (v1.0)

Pack: `core` — 16 skills (3 universal + 13 stack profiles).

**Process:** [docs/skills-review.md](../../docs/skills-review.md)

**Automated:** `./scripts/kit validate-skills --pack=core`

| Skill | Agent | Agent notes | Human |
|-------|-------|-------------|-------|
| stack-detection | OK | Matches [stack-detection.md](../../docs/stack-detection.md), `registry/stacks.yaml`; defers tooling to stack skills | pending |
| stack-loader | OK | Profile field table matches `profile.yaml` schema used by detect-stack; lazy load aligns with architecture | pending |
| testing-universal | OK | Aligns with [TESTING.md](../../docs/guidelines/TESTING.md); defers runners to profile.tooling | pending |
| stacks/django | OK | Thin router; source of truth `profile.yaml`; matches stack-agnostic rule | pending |
| stacks/elixir | OK | Same pattern as django | pending |
| stacks/fastapi | OK | Same pattern | pending |
| stacks/flask | OK | Same pattern | pending |
| stacks/go | OK | Same pattern | pending |
| stacks/nextjs | OK | Same pattern | pending |
| stacks/node | OK | Same pattern | pending |
| stacks/nuxt | OK | Same pattern | pending |
| stacks/python | OK | Same pattern | pending |
| stacks/rails | OK | profile.yaml tooling (rspec, rubocop, brakeman) matches Rails conventions | pending |
| stacks/rust | OK | Thin router + profile | pending |
| stacks/svelte | OK | Thin router + profile | pending |
| stacks/sveltekit | OK | Thin router + profile | pending |

## Agent batch summary

- **Universal skills** route to guidelines and `detect-stack.sh` — no framework commands embedded.
- **Stack skills** are intentionally thin: `SKILL.md` + `profile.yaml` + `profile.json`; deep patterns belong in future pattern packs (stash), not core.
- **No broken doc links** in universal skills; stack skills link only to local `profile.yaml`.

## Human sign-off (pack)

- [ ] I reviewed at least 3 skills full-text: _______________
- [ ] I ran `./scripts/kit validate-skills --pack=core` — PASS
- [ ] I ran `./scripts/kit deploy-skills --pack=core --dry-run` — paths look correct
- [ ] **Pack approved for merge:** YYYY-MM-DD — _______________
