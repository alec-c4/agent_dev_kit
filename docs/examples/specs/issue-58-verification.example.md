# Verification: Fix CSV export UTF-8 / empty file

**Work ref:** GH-58  
**Agent:** verifier (fresh session)  
**Verdict:** PASS  
**Scope:** `feature/fix-csv-utf8` — `git diff main...HEAD`

## Executable checks

| Check | Command | Result | Notes |
|-------|---------|--------|-------|
| tests | `bundle exec rspec spec/services/records/csv_export_spec.rb spec/requests/records_export_spec.rb` | PASS | 12 examples, 0 failures |
| lint | `bundle exec standardrb` | PASS | no offenses in changed files |
| typecheck | — | SKIP | not defined in stack profile |

## Documentation

| Item | Status | Evidence |
|------|--------|----------|
| Public changes documented | PASS | `docs/api/records.md` — UTF-8 BOM, charset header |
| Docs match implementation | PASS | export response headers match doc |

## Spec conformance

Spec: `.ai/specs/export-csv-spec.md` **v1.1** (legacy: `issue-42-spec.md`)

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | PASS | `records_export_spec.rb:18` — 200, charset, filename |
| AC-2 | PASS | `csv_export_spec.rb:42` — filters applied |
| AC-3 | PASS | `records_export_spec.rb:31` — 401 unauthenticated |
| AC-4 | PASS | `csv_export_spec.rb:55` — policy isolation |
| AC-5 | PASS | `csv_export_spec.rb:12` — header-only + BOM |
| AC-6 | PASS | `csv_export_spec.rb:28` — Cyrillic fixture |

## Blockers

- None

## Verifier sign-off

Task ready for human review and commit: **YES**
