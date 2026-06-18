# Plan: CSV export for record list

**Detail:** standard  
**Work ref:** GH-42  
**Spec:** specs/export-csv-spec.md **v1.0** (approved) — legacy alias `issue-42-spec.md`

## Summary

Add CSV export action sharing index scope and authorization.

## Stack

From profile: `stacks/rails` — `bundle exec rspec`, `standardrb`

## Implementation steps

- [ ] Route: `GET /records/export` → `records#export` (namespaced if project uses modules)
- [ ] `app/services/records/csv_export.rb` — build CSV from relation, header row, row cap 10_000
- [ ] `RecordsController#export` — authorize with same policy as `index`, call service, set headers (AC-1)
- [ ] Do **not** add gems — use Ruby `CSV` stdlib unless plan revision approved
- [ ] `spec/services/records/csv_export_spec.rb` — AC-2 filters, AC-4 isolation
- [ ] `spec/requests/records_export_spec.rb` — AC-1, AC-3 auth
- [ ] Update `docs/api/records.md` — export endpoint (for VERIFICATION docs check)

## Phases

### Phase 1 — Service + tests (M)

- [ ] TDD service and request specs per AC IDs

### Phase 2 — Docs (S)

- [ ] API doc section matches response headers and limits

## Success criteria

- [ ] AC-1–AC-4 from spec v1.0
- [ ] `.ai/work/GH-42-verification.md` PASS before PR (legacy: `issue-42-verification.md`)
