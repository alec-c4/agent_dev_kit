# Skills pack review process

How to verify a skill pack before merge: **automated checks → agent doc review → human sign-off**.

Applies to `packs/core/` (Phase 2 [P0]) and future pattern packs from stash.

## Three layers

| Layer | Who | Tool / artifact |
|-------|-----|-----------------|
| 1. Structure | CI / agent | `./scripts/kit validate-skills --pack=core` |
| 2. Content | Agent | Compare SKILL.md to kit guidelines + official framework docs |
| 3. Sign-off | Human | `packs/<pack>/VERIFICATION.md` — mark **Human: OK** per skill |

Do not merge a pack until layer 3 is complete for every skill in the manifest (or explicitly waived with reason).

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

## Layer 2 — Agent content review

For **each skill** in the pack manifest:

1. Read `skills/<path>/SKILL.md` and any `profile.yaml`.
2. Cross-check against:
   - Relevant `docs/guidelines/*.md` (no stack detail duplicated in guidelines)
   - `docs/stack-detection.md` for detection/load skills
   - Official framework docs for stack profiles (commands, conventions)
3. Record in `packs/<pack>/VERIFICATION.md`:
   - **Agent:** OK / FIX / N/A
   - One-line note (doc source, fix applied, or waiver)
4. Fix clear errors in SKILL.md; do not expand scope into pattern skills not in this pack.

### Review checklist per skill

| Question | Fail if |
|----------|---------|
| Description triggers on the right tasks? | Vague or generic |
| Stack-specific commands only in stack skills? | RSpec/pytest hardcoded in universal skills |
| Points to profile.yaml / detect-stack? | Guesses tooling from memory |
| Links to guidelines valid? | Broken paths |
| `user-invokable: false` on internal skills? | User should not `$stack-loader` manually |

## Layer 3 — Human sign-off

Human spot-checks (batch is fine — one session per pack):

1. Skim `packs/core/VERIFICATION.md` agent column.
2. Open **2–3 skills you use most** (e.g. `stack-detection`, your stack profile) — read full SKILL.md.
3. Run deploy dry-run:

```bash
./scripts/kit deploy-skills --pack=core --scope=project --dry-run
```

4. Mark **Human: OK** (or note issues) in VERIFICATION.md.
5. Optional: in target app, invoke skill via Codex `$stack-detection` or Antigravity skills list.

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
3. Copy `packs/core/VERIFICATION.md` as template; fill agent + human columns.
4. Full `./scripts/kit validate` before PR.

Pattern skills from stash (rails-core-patterns, etc.) ship in **separate packs** after core is signed off.
