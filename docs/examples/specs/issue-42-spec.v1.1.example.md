# Spec: CSV export for record list

**Document version:** 1.1  
**Status:** approved  
**Task type:** fix  
**Spec key:** export-csv  
**Work ref:** GH-58  
**Tracker link:** https://github.com/org/app/issues/58  
**Supersedes:** 1.0 — see [archive/issue-42-spec.v1.0.example.md](archive/issue-42-spec.v1.0.example.md)

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2026-06-10 | Alexey | Initial spec — CSV export from index page |
| 1.1 | 2026-06-18 | Alexey | Fix #58: UTF-8 BOM for Excel; clarify empty export (AC-5) |

## Goal

Authenticated users can download the current filtered record list as a CSV file from the index page. **v1.1:** CSV opens correctly in Excel for non-ASCII text; empty exports are explicit.

## Scope

- In scope: Same as v1.0, plus UTF-8 BOM and empty-export behaviour.
- Out of scope: Unchanged from v1.0.

## Acceptance criteria

- [ ] **AC-1:** Given an authenticated user with access to the index, when they click "Export CSV", then the response is `200` with `Content-Type: text/csv; charset=utf-8` and a filename `records-YYYY-MM-DD.csv`.
- [ ] **AC-2:** Given index filters (search, status) are applied, when the user exports, then the CSV contains only records matching those filters.
- [ ] **AC-3:** Given an unauthenticated request to the export URL, when the server handles it, then the response is `401` or redirect to login (match existing app auth behaviour).
- [ ] **AC-4:** Given a user without permission to view a record, when they export, then that record is not included in the CSV (same isolation as index).
- [ ] **AC-5:** *(added v1.1)* Given zero matching records, when the user exports, then the response is `200` with header row only and UTF-8 BOM bytes `EF BB BF` at the start of the body.
- [ ] **AC-6:** *(added v1.1)* Given cell values contain non-ASCII characters (e.g. Cyrillic), when opened in Excel on Windows, then characters render correctly (BOM + UTF-8).

## Edge cases

- Empty result set: covered by AC-5 (header only, not an error).
- Large result set: unchanged from v1.0 — max 10_000 rows or `422`.

## Non-goals

- Unchanged from v1.0.

## Open questions

- None.
