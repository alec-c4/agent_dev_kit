---
name: work-intake
description: Normalize work_ref and write .ai/work/{ref}-analysis.md from paste or gh fetch. Use before spec when a ticket or task id is provided.
user-invokable: true
disable-model-invocation: false
---

# Work intake

Normalize **work_ref**, resolve paths from optional `.ai/tracker.yaml`, and create `.ai/work/{work_ref}-analysis.md`. See [TRACKER.md](../../docs/guidelines/TRACKER.md) intake ladder.

## When to use

- User gives a ticket id (`GH-58`, `LIN-ENG-123`) or says «work on ENG-77».
- Before spec/plan when analysis file is missing.
- Called by [resolve-task](../resolve-task/SKILL.md) at pipeline start.

## Intake priority (highest first)

| Step | Action |
|------|--------|
| 1. **Paste** | Always works — human or agent fills analysis body |
| 2. **Single fetch** | `./scripts/kit intake {work_ref}` with `gh` when GitHub ref |
| 3. **Cache** | Optional `.ai/tracker-cache.json` — resolve title/url only; **still write analysis** |

Never skip analysis because cache has a row.

## Protocol

1. **Parse work_ref** from user message or command args. Sanitize for paths (`/` and spaces → `-`).
2. **Read** `.ai/tracker.yaml` if present — `provider`, `work_filename`, `spec_filename`, `url_template`.
3. **Optional cache** — run `./scripts/kit sync-tracker` to refresh `.ai/tracker-cache.json`; enrich title/link in analysis header; do not replace ticket body without paste/fetch.
4. **Run intake script:**

```bash
# Paste (preferred when no gh)
./scripts/kit intake GH-58 --paste <<'EOF'
Title and description from tracker…
EOF

# Or file
./scripts/kit intake GH-58 --file=export/ticket.md

# GitHub fetch when gh is available
./scripts/kit intake GH-58
```

5. **Confirm output path** — default `.ai/work/{work_ref}-analysis.md`.
6. **Suggest spec_key** — existing feature vs new (see TRACKER.md decision tree).

## Analysis minimum

File must include header fields from [TRACKER.md](../../docs/guidelines/TRACKER.md):

- **Work ref**, **Spec key** (if known), **Tracker link**, **Source**
- **Problem**, **Affected areas** (agent completes after code exploration)

## Errors

If script exits non-zero, tell the human exactly what failed (no paste, gh missing, issue not found). Offer paste as fallback.

## Do not

- Call Linear/Jira/GitHub APIs without human-provided access or `gh` CLI.
- Use tracker cache as sole source of truth for requirements.
