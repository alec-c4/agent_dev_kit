# Plan: Scheduled CSV export with email delivery (#100)

**Detail:** detailed  
**Spec:** issue-100-spec.md **v1.0** (approved)

## Summary

Add scheduled export jobs that generate CSV files and email download links to authenticated users. Shares authorization and row limits from the index export feature (#42).

## Stack

From profile: `stacks/rails` — Sidekiq, ActiveStorage, ActionMailer (existing in app)

## Dependencies and risks

| Risk | Mitigation |
|------|------------|
| Large exports block workers | Background job + row cap from spec Constraints |
| Stale download links | Signed URLs with 24h expiry (AC-3) |
| Duplicate schedules | Unique index on `(user_id, schedule_cron)` |

## Phase 0 — Spike (optional, S)

- [ ] Confirm Sidekiq queue capacity for export workload
- [ ] Confirm mailer template pattern matches existing notifications

## Phase 1 — Domain model (M)

- [ ] Migration: `export_schedules` (user_id, cron, filters jsonb, active, timestamps)
- [ ] `ExportSchedule` model — validations, `belongs_to :user`
- [ ] Policy: user can CRUD own schedules only (AC-4)
- [ ] TDD: model + policy specs

## Phase 2 — Export job (L)

- [ ] `Records::ScheduledCsvExportJob` — reuse `Records::CsvExport` service from #42
- [ ] Upload to ActiveStorage; generate signed URL
- [ ] Idempotency key per schedule run window
- [ ] TDD: job spec with AC-1, AC-2, row cap from Constraints

## Phase 3 — Mailer + scheduler (M)

- [ ] `ExportMailer#ready` — link + expiry note (AC-3)
- [ ] Wire cron via existing `config/schedule.yml` pattern
- [ ] Request specs: create schedule, trigger job, assert mail enqueued

## Phase 4 — UI + API (M)

- [ ] Settings page: list/create/pause schedules
- [ ] API endpoints if mobile client exists — mirror HTML auth
- [ ] Update `docs/api/records.md` — scheduled export section

## Phase 5 — Observability (S)

- [ ] Log export duration and row count (no PII in logs)
- [ ] Metric hook if project uses StatsD — `export.scheduled.completed`

## Rollback

- Feature flag `scheduled_csv_export` — disable cron registration without migration rollback
- Job safe to drain; schedules remain in DB

## Success criteria

- [ ] AC-1–AC-5 from spec v1.0
- [ ] `.ai/issue-100-verification.md` PASS before PR
- [ ] No new gems without human approval (spec Constraints)
