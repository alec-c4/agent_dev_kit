# Handoff: GH-58 — CSV export encoding fix

**Work ref:** GH-58  
**Comprehension tier:** standard  
**Spec:** specs/export-csv-spec.md v1.1  

## What changed

- Export endpoint sets `Content-Type` with `charset=utf-8`.
- CSV rows pass through `CsvEncoder` before streaming.
- Added request spec for BOM-free UTF-8 body.
- Updated API doc for `/exports/csv` response headers.

## Data flow

Client GET `/exports/csv` → `ExportsController#csv` → `Export::CsvBuilder` reads rows → `CsvEncoder.encode` → streamed response. No temp file; encoding applied per chunk.

## Key files

| Path | Role |
|------|------|
| `app/controllers/exports_controller.rb` | Sets charset header, delegates build |
| `app/services/export/csv_builder.rb` | Row assembly |
| `app/services/csv_encoder.rb` | UTF-8 normalization |
| `spec/requests/exports/csv_spec.rb` | AC-1, AC-2 coverage |

## Decisions

- Normalized in `CsvEncoder` instead of the controller — reuse for future export formats.
- No BOM — spec AC-2 forbids byte-order mark for Excel compatibility.

## If it breaks

Check `CsvEncoder` for invalid byte sequences; confirm `Content-Type` in browser network tab; run `spec/requests/exports/csv_spec.rb`.

## Manual verification (from spec)

| AC | Scenario | Human result |
|----|----------|--------------|
| AC-2 *(human-verify)* | Download CSV with café in name; open in Excel; accents render | PASS — tested locally 2026-06-18 |

## Comprehension Q&A

### Q1
**Question:** Where is UTF-8 enforced — controller, encoder, or both?  
**Human answer:** Encoder normalizes bytes; controller only sets charset header on the response.

### Q2
**Question:** What happens if a row contains invalid encoding?  
**Human answer:** CsvEncoder replaces invalid sequences per spec AC-3 (replacement character).

### Q3
**Question:** Why is there no BOM?  
**Human answer:** AC-2 — Excel on Windows mis-reads BOM for this team's export flow.

## Human sign-off

- **Files I read:** `app/services/csv_encoder.rb`, `spec/requests/exports/csv_spec.rb`
- **I can explain:** Export streams UTF-8 CSV with charset header and encoder normalization, no BOM.
- **Signed:** 2026-06-18
