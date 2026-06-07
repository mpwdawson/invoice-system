# Epic: Work Tracker & Invoice System

A single Rails app to replace an Excel-based contractor billing workflow. Track daily work tasks, log time in 0.5hr blocks, manage Jira ticket references and project codes, and generate monthly invoices per client.

**Current invoice number:** `0315`. New invoices start at `0316`.

---

## Story Map

```
Setup          → Customer Mgmt  → Task Mgmt  → Time Logging  → Reporting  → Invoicing  → LLM  → PDF
─────────────────────────────────────────────────────────────────────────────────────────────────────
Auth + Profile   Customers         Tasks         Quick Entry     Monthly      Wizard       Names  Generation
                 Rates             Tickets       Edit History    Daily Log    Lifecycle           (deferred)
                 Project Codes     Archive       Day View        Task Totals  Soft Lock
```

---

## Stories

### S-01: App Bootstrap & Auth
**Goal:** Skeleton Rails app with single-password authentication and a contractor profile settings screen.

**Acceptance criteria:**
- `rails server` boots and serves the app
- Visiting any page without a session redirects to a login screen
- Login screen accepts a password configured via `ENV["APP_PASSWORD"]`
- Session persists across page loads; logout link clears it
- Settings screen at `/settings` allows editing:
  - Name, address, email, tax number, bank/payment details
- One `ContractorProfile` row; the screen creates it on first visit if absent

**Tech notes:**
- No Devise. Simple `SessionsController` with bcrypt or plain ENV comparison.
- Contractor profile stored in `contractor_profiles` table (single row).

---

### S-02: Customer Management
**Goal:** Create and manage client records including billing rates and project codes.

**Acceptance criteria:**
- CRUD for customers: name, address, contact name/email, invoice prefix, `requires_project_codes` toggle
- Rate history: add a new rate with `effective_from` date; list shows all historical rates in descending order; current rate highlighted
- Project codes: CRUD per customer (code + description + active toggle); archived codes hidden from entry UIs but preserved on historical data
- Customer index shows current rate and project code count

**Tech notes:**
- `CustomerRate.current_for(customer, date)` class method returns the effective rate for a given date.
- Turbo Frames for inline editing of rates and project codes without full page reload.
- Seed `Invoice.sequence_number` starting at 316 in this story or S-01.

---

### S-03: Task Management
**Goal:** Create, edit, assign, and archive tasks. Manage ticket references and project code assignment.

**Acceptance criteria:**
- Create task: title, customer, optional project code, optional notes, `billable` toggle (default on)
- Ticket references: add/remove `prefix + number` pairs (e.g. `AW-6522`). Parser handles bulk input like `AW-6770 & AW-6771`
- `invoice_name` field editable on task; shown as blank with placeholder "Generated at invoice time"
- Archive a task (hidden from entry UI autocomplete; preserved on all historical records)
- Task detail page shows: all ticket refs, project code, billable status, total hours logged (all time), list of time entries
- Search/filter tasks by title, ticket number, customer, project code, status, billable

**Tech notes:**
- `Task.search(query)` should match on title, ticket ref prefix+number
- Status: `active` (default) / `archived`
- `billable: true` is the default — non-billable is rare and opt-in

---

### S-04: Log Time (Quick Entry + History — combined screen)
**Goal:** The primary daily-use screen. Entry form at top, scrollable date-grouped log below. Covers both logging today's hours and editing/correcting past entries. Login redirects here by default.

**Acceptance criteria:**
- Entry form at top: date (defaults to today), task search/autocomplete, hours input
- Task search matches active tasks by title + ticket refs; shows customer and project code in dropdown results
- Preview panel (Turbo Frame) updates as user types — shows task name, customer, project code; if entry exists for task+date shows "Already logged Xhr → adding Y → new total: Zhr"
- Hours validated as multiples of 0.5; error shown inline
- Save creates or upserts the `[task_id, date]` TimeEntry; form resets (date persists, task clears) for fast multi-entry
- If task not found: inline "Create new task" expansion in the search dropdown (Turbo Frame) — title pre-filled, user selects customer + optional project code, saves without leaving the page, then auto-selects the new task
- Below the form: last 14 days grouped by date, most recent first. Each group shows: date header with daily total, entries (task title, hours, project code, billed/unbilled badge), `[ + Add entry ]` prompt. Empty days show explicitly so gaps are visible.
- Click any entry → inline edit of hours and/or date via Turbo Stream
- Click `[ + Add entry ]` on a past date → pre-fills date in the entry form at top
- Billed entries (have `invoice_id`) show soft-lock warning before edit or delete — allowed after confirmation
- Delete unbilled entry with confirmation
- Entry can be moved to a different date ("logged on the wrong day")

**Tech notes:**
- Turbo Frame for the preview panel
- Turbo Stream for inline save/edit without full page reload
- Stimulus controller for date picker, form reset, and inline edit toggling

---

### S-05: *(merged into S-04)*

---

### S-06: Data Import
**Goal:** One-time import of recent work history from Excel/CSV format.

**Acceptance criteria:**
- Import screen accepts a CSV file or paste of raw text in the existing format:
  `- AW-6522 DesignRequest Polymorphic Refactor (5), Meetings (1), Deploy prep (0.5)`
- Parser extracts: date (from row position or explicit), task title, ticket refs, hours
- Preview of parsed results before committing: shows each proposed TimeEntry with matched/new Task
- User can correct mismatches before import (e.g. assign project code, fix a task name)
- Duplicate detection: skips entries where a TimeEntry for `[task_id, date]` already exists
- Import report: X entries created, Y skipped (duplicate), Z tasks created, W tasks matched

**Tech notes:**
- Write `Import::ParseLogService` from scratch — the original parse scripts have been deleted.
- Import is a one-time operation — no need for scheduled or recurring import

---

### S-07: Reports
**Goal:** Three v1 reports replacing manual Excel summing.

**All reports filter by `time_entry.date`** — the date work happened. Never by invoice date or creation date. Only billable TimeEntries (`task.billable = true`) are counted in all totals.

#### Report 1: Monthly Hours by Project Code
- Pick customer + month (or custom date range)
- Shows: `Project Code | Description | Hours` — the format needed for invoice prep
- Only tasks with a project code appear; tasks without (Meetings etc.) are excluded from the chart but their hours appear in the grand total
- Grand total hours includes all billable entries in the period regardless of project code
- Exportable as CSV

#### Report 2: Daily / Weekly Log
- Date-grouped list view of all time entries, most recent first
- Filter by customer, date range
- Shows: date → task title → ticket refs → hours → project code → invoice status
- Replaces the habit of "scrolling through the Excel tab"

#### Report 3: Task Total Hours
- Per-task summary: title, ticket refs, customer, project code, total hours across all time
- Filter by customer, project code, status (active/archived), billable
- Useful for answering "how much total time did AW-6522 take across all months?"

---

### S-08: Invoice Wizard
**Goal:** End-of-month invoice creation wizard.

**Steps:**
1. **Pick customer + date range** (default: current month; can be any range, e.g. 2-week billing)
2. **Review un-billed time entries** — shows all billable `TimeEntry` records in range with `invoice_id: nil` for that customer. Grouped by task. Shows total hours. Soft lock warning if any entry in the period is already on a sent invoice.
3. **Craft invoice lines** — user writes/edits description lines for the client. Each line is free text (`description` only — no hours). User selects which tasks are context for each line (`task_ids` JSON, used by LLM). Add, reorder, delete lines freely. A line can cover one task or many.
4. **Generate descriptions (LLM)** — button fires bulk LLM request using `task.title`, `task.invoice_name`, ticket refs, and notes as context. Populates blank descriptions. User reviews and edits.
5. **Preview** — rendered invoice: description lines + project summary (if `requires_project_codes`) + total hours + total amount
6. **Finalize** — snapshots `total_hours` and `total_amount` onto invoice. Stamps all included `TimeEntry` records with `invoice_id`. Sets `status: ready`. Assigns `invoice_number` from `sequence_number`.

**Acceptance criteria:**
- Invoice number derived from auto-incremented `sequence_number` + customer prefix (e.g. `ARGEN-0316`)
- Rate auto-populated from `CustomerRate` effective on `period_start`
- `total_hours` = SUM of all billable TimeEntries in the selected set (not from line items)
- `total_amount` = `total_hours × rate`
- Project summary computed from TimeEntries grouped by `task.project_code` (tasks without project code excluded from chart but included in total)
- Wizard state persists across page loads
- Invoice status transitions: `draft` → `ready` → `sent` (stamps `sent_at`) → `paid` (stamps `paid_at`)
- Status change to `sent` requires confirmation

---

### S-09: LLM Invoice Description Generation
**Goal:** Integrate local LLM (Qwen via llama REST API) for bulk invoice line description generation.

**Acceptance criteria:**
- `LlmClient` service object: configurable endpoint URL + model (via ENV). Pattern extracted from OpenClaw codebase — do not rebuild from scratch.
- `InvoiceDescriptionGenerator` service: takes a list of tasks (title + `invoice_name` hint + ticket refs + notes) per invoice line, returns suggested client-facing descriptions
- Graceful degradation: LLM unavailable/timeout → error shown per line → lines stay blank for manual entry → does not block wizard
- Prompt uses old invoices as few-shot examples (user to provide sample invoice PDFs)
- Results are suggestions only — user reviews and edits every line before finalizing
- Configurable timeout via `LLM_TIMEOUT` ENV (default 30s)
- LLM call must **not** run inside a DB transaction

**Tech notes:**
- LLM is entirely optional — app is fully functional without it
- No streaming UI for v1 (synchronous call with spinner)
- Future: Solid Queue job + Turbo Stream broadcast when hardware improves
- Future: prompt template configurable per customer

---

### S-10: PDF Invoice Generation *(deferred)*
**Goal:** Generate a PDF invoice for a finalized invoice record.

**Status:** Deferred. Requirements depend on:
- Sample PDFs from primary customer as spec input
- Per-customer template/format strategy (primary customer requires project summary; others may differ)
- Tooling choice: Prawn, WickedPDF, Typst, or HTML-to-PDF

**Known invoice structure (primary customer):**
```
[Header]        contractor details, client details, invoice number, date, period

[Line Items]    description-only lines (no hours per line), e.g.:
                  "Added Rewards Customer Dashboard"
                  "Refactored Design Request data model"

[Project Summary]  Project Code | Description | Hours
                   (only for customers with requires_project_codes: true)
                   (tasks without project code excluded from chart, included in total)

[Total]         Total Hours: N  |  Rate: $X/hr  |  Amount Due: $Y
```

**What the data model already supports:**
- `InvoiceLine` has `description`, `sort_order`, `task_ids` (LLM context)
- `Invoice` has `rate`, `total_hours`, `total_amount`, `period_start`, `period_end`, `invoice_number`, `sent_at`
- Project summary computed from TimeEntries stamped with `invoice_id`, grouped by `task.project_code`
- `ContractorProfile` has all header fields (name, address, email, tax_number, bank_details)
- `Customer` has address and contact info

---

### S-11: Docker & Deployment *(deferred)*
**Goal:** Containerize for home server deployment with SQLite volume mount.

**Status:** Deferred until the app is stable and the first invoice has been generated.

**Notes:**
- SQLite file on host volume at e.g. `/data/invoice.db`
- Litestream considered but deferred — manual cron backup to Google Drive / Dropbox sufficient for now
- `ENV["APP_PASSWORD"]` and `ENV["LLM_ENDPOINT"]` passed via Docker env or `.env` file

---

### S-12: Backup *(deferred — high priority when running in production)*
**Goal:** Ensure `storage/production.sqlite3` is backed up regularly.

**Status:** Deferred. Must be in place before the app is used for real invoicing.

**Notes:**
- This file is the entire business's financial records. Loss is unrecoverable.
- Approach: cron job on the host machine copies the SQLite file to Google Drive / Dropbox on a daily schedule
- SQLite `.backup` command (or plain `cp` while app is idle) is sufficient
- Litestream (continuous WAL replication to S3/B2) is the more robust future option
- No app code needed — purely a host-level operations task

---

## Story Sequencing (Suggested Build Order)

```
S-01 Bootstrap & Auth
  ↓
S-02 Customer Management       ← seed invoice sequence at 316
  ↓
S-03 Task Management
  ↓
S-04 Log Time                  ← first "real" daily-use feature (entry + history, combined screen)
  ↓
S-05 (merged into S-04)
  ↓
S-06 Data Import               ← bring in recent Excel history
  ↓
S-07 Reports                   ← start seeing the data
  ↓
S-08 Invoice Wizard            ← generate first invoice
  ↓
S-09 LLM Descriptions          ← polish the invoice flow
  ↓
S-10 PDF Generation            ← send to client
  ↓
S-11 Docker                    ← productionize
  ↓
S-12 Backup                    ← must complete before relying on app for real data
```

---

## Out of Scope (v1)

- Multi-user / team access
- Time-tracking timers
- Expense tracking
- Recurring tasks
- Client portal / self-service
- Payment processing
- Budget/target tracking per project code
- Mobile app
