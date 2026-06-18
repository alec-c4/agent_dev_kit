# Skills pack review process

How to verify a skill pack before merge: **automated checks → agent doc review → human sign-off in the PR**.

Applies to `packs/core/` (Phase 2 [P0]) and future pattern packs from stash.

## Three layers

| Layer | Who | Tool / artifact |
|-------|-----|-----------------|
| 1. Structure | CI / agent | `./scripts/kit validate-skills --pack=<pack>` |
| 2. Content | Agent | Compare SKILL.md to kit guidelines + official framework docs |
| 3. Sign-off | Human | PR review — checklist in PR description (not committed to repo) |

Do not merge a pack until layer 3 is complete for every skill in the manifest (or explicitly waived with reason in the PR).

## Layer 1 — Automated validation

```bash
bash scripts/compile_registry.sh
./scripts/kit validate-skills --pack=core --report=packs/core/validate-report.md
./scripts/kit validate --phase=1
```

Checks:

- Every manifest skill has `SKILL.md`
- YAML frontmatter: `name`, `description` (Agent Skills standard)
- Stack skills have `profile.yaml`
- Relative markdown links in SKILL.md resolve

CI runs the same checks via [.github/workflows/validate.yml](../.github/workflows/validate.yml).

## Layer 2 — Agent content review

For **each skill** in the pack manifest:

1. Read `skills/<path>/SKILL.md` and any `profile.yaml`.
2. Cross-check against:
   - Relevant `docs/guidelines/*.md` (no stack detail duplicated in guidelines)
   - `docs/stack-detection.md` for detection/load skills
   - Official framework docs for stack profiles (commands, conventions)
3. Note in the PR (agent column): **OK** / **FIX** / **N/A** plus one-line rationale.
4. Fix clear errors in SKILL.md; do not expand scope into pattern skills not in this pack.

### Review checklist per skill

| Question | Fail if |
|----------|---------|
| Description triggers on the right tasks? | Vague or generic |
| Stack-specific commands only in stack skills? | RSpec/pytest hardcoded in universal skills |
| Points to profile.yaml / detect-stack? | Guesses tooling from memory |
| Links to guidelines valid? | Broken paths |
| `user-invokable: false` on internal skills? | User should not `$stack-loader` manually |

## Layer 3 — Human sign-off (PR only)

Human spot-checks (batch is fine — one session per pack). Record in the **PR description**, not in git:

```markdown
## Skills pack sign-off

- [ ] CI green (`validate` + `validate-skills`)
- [ ] Reviewed full text of 2–3 skills I use most
- [ ] `./scripts/kit deploy-skills --pack=core --dry-run` — paths look correct
- [ ] Pack approved for merge — YYYY-MM-DD
```

Optional local notes (gitignored): copy [docs/examples/pack-verification.local.md.example](examples/pack-verification.local.md.example) to `packs/<pack>/VERIFICATION.local.md` in your clone only.

## Deploy after approval

```bash
./scripts/kit install --target=all --project
# or
./scripts/kit deploy-skills --pack=core --scope=both --sync-antigravity-cli
```

Paths: [tool-adapters.md](tool-adapters.md).

## Adding a pack (future)

1. Add `packs/<id>/manifest.yaml` — list only skills that exist under `skills/`.
2. Run compile + validate-skills.
3. Open PR with the sign-off checklist above.
4. Full `./scripts/kit validate` before merge.

Pattern skills from stash (rails-core-patterns, etc.) ship in **separate packs** after core is signed off.
