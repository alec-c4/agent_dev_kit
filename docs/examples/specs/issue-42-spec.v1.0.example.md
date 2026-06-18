# Spec: CSV export for record list

**Document version:** 1.0  
**Status:** approved  
**Task type:** new  
**Issue:** #42  
**Supersedes:** —

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2026-06-10 | Alexey | Initial spec — CSV export from index page |

## Goal

Authenticated users can download the current filtered record list as a CSV file from the index page.

## Scope

- In scope: CSV download for records the user can already see on index (same filters and authorization as HTML index).
- Out of scope: Excel format, scheduled exports, export of unrelated resources, admin bulk export API.

## Acceptance criteria

- [ ] **AC-1:** Given an authenticated user with access to the index, when they click "Export CSV", then the response is `200` with `Content-Type: text/csv` and a filename `records-YYYY-MM-DD.csv`.
- [ ] **AC-2:** Given index filters (search, status) are applied, when the user exports, then the CSV contains only records matching those filters.
- [ ] **AC-3:** Given an unauthenticated request to the export URL, when the server handles it, then the response is `401` or redirect to login (match existing app auth behaviour).
- [ ] **AC-4:** Given a user without permission to view a record, when they export, then that record is not included in the CSV (same isolation as index).

## Edge cases

- Empty result set: CSV contains header row only.
- Large result set: export respects the same pagination cap as index (max 10_000 rows) or returns `422` with a clear message if over limit.

## Non-goals

- Column customization UI.
- Background job for large exports (future issue).

## Constraints

- Must use existing `AuthorizationPolicy` for record access — no ad-hoc checks in the controller.
- Must not add gems without human approval — use Ruby `CSV` stdlib.
- Export must reuse the same scoped relation as the HTML index (no duplicate query logic in the controller).

## Open questions

- None (resolved before approval).
