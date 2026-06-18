# Plan: Fix CSV export UTF-8 / empty file

**Detail:** standard  
**Work ref:** GH-58  
**Spec:** specs/export-csv-spec.md **v1.1** (approved) — legacy alias `issue-42-spec.md`

## Stack

Detected from profile: `stacks/rails` (example)

## Phase 1 — Export service (S)

- [ ] `app/services/records/csv_export.rb` — prepend BOM, UTF-8 encode
- [ ] Tests: AC-5 empty header-only, AC-6 Cyrillic fixture

## Phase 2 — Controller + docs (S)

- [ ] `RecordsController#export` — use service; `charset=utf-8` in header (AC-1)
- [ ] Update `docs/api/records.md` export section to mention UTF-8 BOM

## Success criteria

- [ ] All AC-1–AC-6 from spec v1.1
- [ ] Verification report in `.ai/work/GH-58-verification.md` (legacy: `issue-58-verification.md`)
