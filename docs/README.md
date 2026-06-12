# Invoice Tracker — Wiki

Design documentation for the Work Tracker & Invoice System Rails app.

## Documents

- [System Overview](system-overview.md) — Purpose, tech stack, deployment, core philosophy
- [Architecture](architecture.md) — Rails 8.1, SQLite, Turbo patterns, LLM integration, testing stack
- [Data Model](data-model.md) — Full schema, relationships, key queries
- [Workflows](workflows.md) — ASCII diagrams: daily entry, invoice wizard, lifecycles, data flow
- [Design Decisions](design-decisions.md) — Key decisions and rationale from the design session
- [Epic & Stories](epic-invoice-tracker.md) — S-01 through S-12 with acceptance criteria and build order
- [Build Plan](build-plan.md) — 25 session-sized chunks with dependencies, key files, and done criteria

## Quick Reference

**Current invoice number:** `0315` → next is `ARGEN-0316` (seed `sequence_number = 316`)

**Tech:** Rails 8.1.3 / Ruby 4.0.5 / SQLite (3 files) / Tailwind / Importmap / Stimulus / Turbo / RSpec

**Core model:**
```
Customer
  ├── CustomerRate (rate history)
  ├── ProjectCode
  ├── Task ──── TicketReference
  │     └────── TimeEntry ──── Invoice
  └── Invoice ─ InvoiceLine (descriptions only)
```

**Key rules:**
- One TimeEntry per [task, date] — unique index, same-day hours increment existing entry
- Invoice total = SUM of billable TimeEntries stamped with invoice_id (not from line items)
- Invoice lines = client-facing descriptions only, no hours per line
- Project summary = computed from TimeEntries grouped by project_code
- Reports always filter by time_entry.date (never invoice date)

**Daily workflow:** Log Time screen → search task → log hours → see today's log below → edit/backdate as needed

**Monthly workflow:** Invoice wizard (6 linear steps) → customer + date range → review entries → craft description lines → LLM descriptions → preview → finalize

**Stories:** S-01 Auth → S-02 Customers → S-03 Tasks → S-04 Log Time (entry + history, combined) → S-06 Import → S-07 Reports → S-08 Invoice Wizard → S-09 LLM → S-10 PDF → S-11 Docker → S-12 Backup
