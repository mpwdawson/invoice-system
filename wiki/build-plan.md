# Build Plan

Each chunk is scoped to fit comfortably in one coding session — small enough to finish without hitting a context wall, large enough to produce something testable and shippable. Every chunk ends with `bundle exec rspec` green and `bin/brakeman --no-pager` clean.

**Rule:** Never start a chunk without reading its listed key files first. Never end a chunk without running `bundle exec rspec`.

---

## Dependency Map

```
B-00 rails new (OS setup, Ruby, gems)
  └─ B-01 Gemfile + SQLite 3-file config (all envs) + RSpec setup
       └─ B-02 Auth
            └─ B-03 Layout + Dark Mode
                 └─ B-04 ContractorProfile Settings
                      │
                      ├─ B-05 Customer CRUD         ← must precede B-07
                      │    └─ B-06 CustomerRate + ProjectCodes
                      │         └─ B-07 Task CRUD
                      │              └─ B-08 TicketReferences
                      │                   └─ B-09 Task Search
                      │                        └─ B-10 TimeEntry model
                      │                             └─ B-11 Entry form + preview
                      │                                  └─ B-12 Inline task creation
                      │                                       └─ B-13 History log
                      │                                            └─ B-14 Inline edit + soft lock
                      │
                      ├─ B-15 Import parser (S-06)  ← after B-09 (needs Tasks/TicketRefs)
                      │    └─ B-16 Import UI
                      │
                      ├─ B-17 Monthly Hours report  ← after B-10 (needs TimeEntries)
                      │
                      ├─ B-18 Daily Log + Task Totals
                      │
                      └─ B-19 Invoice model + wizard shell  ← after B-10
                           └─ B-20 Wizard steps 1–2
                                └─ B-21 Wizard steps 3–4
                                     └─ B-22 Wizard steps 5–6 (FinalizeService)
                                          └─ B-23 Invoice lifecycle (sent/paid)
                                               └─ B-24 LlmClient
                                                    └─ B-25 DescriptionGenerator + wiring
```

---

## Chunks

### Phase 0 — App Setup

#### B-00: `rails new` + OS dependencies
**Goal:** A bootable Rails app on this machine. Resolves any Ruby version, gem, or OS dependency issues before any real code is written.

**Key actions:**
- Confirm Ruby 4.0.5 is active (`ruby -v`)
- `rails new invoice-system --database=sqlite3 --asset-pipeline=propshaft --css=tailwind --javascript=importmap --skip-action-mailer --skip-action-text --skip-active-storage`
- Verify `rails server` boots and serves the default welcome page
- Commit the generated skeleton

**Done when:** `rails server` boots cleanly. No gem install errors. Working directory is a git repo.

---

### Phase 1 — Foundation (S-01)

#### B-01: Gemfile + SQLite 3-file config + RSpec setup
**Goal:** Dependencies locked, three-database SQLite config across all environments, RSpec wired up.

**Key files:** `Gemfile`, `config/database.yml`, `spec/rails_helper.rb`

**Key actions:**
- Add to Gemfile: `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`, `brakeman`
- Run `bin/rails generate rspec:install`; configure `spec/rails_helper.rb`
- Configure `config/database.yml` for **all three environments** (development, test, production) with 3 SQLite files each (primary / queue / cache)
- Run `bin/rails db:migrate` — ensures Solid Queue and Solid Cache schemas load cleanly in all envs
- Verify `bundle exec rspec` runs (0 examples, no errors)
- Verify `bin/brakeman --no-pager` passes clean

**Done when:** `bundle exec rspec` loads cleanly. Brakeman clean. All three DB files initialise in development and test.

---

#### B-02: Auth
**Goal:** Single-password login wall. All pages redirect to `/login` without a session.

**Key files:** `app/controllers/application_controller.rb`, `app/controllers/sessions_controller.rb`, `app/views/sessions/new.html.erb`

**Key actions:**
- `before_action :require_login` on `ApplicationController`
- `SessionsController#create` compares bcrypt digest of `ENV["APP_PASSWORD"]`
- Login form at `/login`; logout at `DELETE /logout`

**Specs:** `spec/requests/sessions_spec.rb` — redirect without session, valid login, invalid login, logout.

**Done when:** Visiting any page without a session redirects to `/login`. Valid password sets session.

---

#### B-03: Sidebar layout + dark mode
**Goal:** Application shell. Fixed left sidebar, nav links, dark mode toggle.

**Key files:** `app/views/layouts/application.html.erb`, `app/javascript/controllers/dark_mode_controller.js`

**Key actions:**
- Left sidebar: nav links for Log Time / Tasks / Customers / Reports / Invoices / Settings
- Dark mode toggle in sidebar header
- Stimulus `dark-mode` controller: toggles `dark` on `<html>`, persists to `localStorage`
- **Add `data-turbo-permanent` to the sidebar element** so Turbo Morphing doesn't reset the `dark` class or Stimulus state on navigation
- Dark mode controller also re-applies the class on `turbo:load` and `turbo:morph` events to guard against morph edge cases
- Tailwind `darkMode: 'class'` configured
- Flash message region in main content area

**Done when:** Sidebar renders on all pages. Dark mode toggles, persists on reload, and survives page navigation without flickering.

---

#### B-04: ContractorProfile settings
**Goal:** Single-row settings screen at `/settings`.

**Key files:** `app/models/contractor_profile.rb`, `app/controllers/settings_controller.rb`, `app/views/settings/`

**Key actions:**
- `ContractorProfile` model: name, address, email, tax_number, bank_details
- Migration: table with those columns (no FK indexes needed — singleton table)
- `SettingsController` uses `first_or_initialize` — always one row
- Form: edit all fields, save, flash confirmation

**Specs:** `spec/models/contractor_profile_spec.rb` — validations. `spec/requests/settings_spec.rb` — GET/PATCH.

**Done when:** `/settings` loads, edits persist, single-row constraint holds.

---

### Phase 2 — Customer Management (S-02)

#### B-05: Customer CRUD
**Goal:** Create, read, update, list customers.

**Key files:** `app/models/customer.rb`, `app/controllers/customers_controller.rb`, `app/views/customers/`

**Key actions:**
- Columns: name, address, contact_name, contact_email, invoice_prefix, requires_project_codes
- Migration includes no FK indexes (no parent table)
- Standard CRUD — index, show, new/create, edit/update. No delete.
- Customer index shows name, invoice_prefix, requires_project_codes (rate + project code count added in B-06)

**Specs:** `spec/models/customer_spec.rb`, `spec/requests/customers_spec.rb`.

**Done when:** Full customer CRUD works. Invoice prefix present.

---

#### B-06: CustomerRate + ProjectCodes
**Goal:** Rate history and project codes per customer. Update customer index to show current rate and project code count.

**Key files:** `app/models/customer_rate.rb`, `app/models/project_code.rb`, `app/controllers/customer_rates_controller.rb`, `app/controllers/project_codes_controller.rb`

**Key actions:**
- `CustomerRate`: customer_id, rate decimal(10,2), effective_from date. **Migration: index on `customer_id`.**
- `CustomerRate.current_for(customer, date)` class method
- Add rate form inline on customer show page (Turbo Frame)
- `ProjectCode`: customer_id, code, description, active boolean. **Migration: index on `customer_id`.**
- CRUD inline on customer show page (Turbo Frame)
- Update customer index to show current rate (via `current_for`) and project code count

**Note:** Invoice sequence seed (starting at 316) is in B-19 where the invoices table is created.

**Specs:** `spec/models/customer_rate_spec.rb` — `current_for` edge cases (multiple rates, boundary date, no rates). `spec/models/project_code_spec.rb`.

**Done when:** Rate history and project codes show on customer page. Customer index shows current rate and project-code count.

---

### Phase 3 — Task Management (S-03)

#### B-07: Task CRUD
**Goal:** Create, view, edit tasks. Customer, project code, billable flag.

**Key files:** `app/models/task.rb`, `app/controllers/tasks_controller.rb`, `app/views/tasks/`

**Key actions:**
- Columns: customer_id, project_code_id (nullable), title, invoice_name (nullable), notes, status (default `active`), billable (default `true`)
- **Migration: indexes on `customer_id`, `project_code_id`, `status`.**
- Index with filters (customer, status, billable). Archive/unarchive action.
- Task show page: title, ticket refs placeholder, notes, billable flag, `invoice_name` field (editable, placeholder "Generated at invoice time"). **Total hours and time entries list are stubbed/hidden at this point — deferred until B-10 when TimeEntry exists.**

**Specs:** `spec/models/task_spec.rb` — validations, scopes (active, archived, billable).

**Done when:** Task CRUD works. Archive hides from active list. `invoice_name` editable with correct placeholder.

---

#### B-08: TicketReferences
**Goal:** Add/remove Jira ticket refs. Handle bulk input like `AW-6770 & AW-6771`.

**Key files:** `app/models/ticket_reference.rb`, `app/services/tasks/parse_ticket_refs_service.rb`

**Key actions:**
- `TicketReference`: task_id, prefix, number. **Migration: unique index on `[task_id, prefix, number]`, index on `task_id`.**
- `Tasks::ParseTicketRefsService` parses `AW-6770 & AW-6771 Title` → `[{prefix: "AW", number: 6770}, ...]`
- Add/remove refs inline on task show (Turbo Stream)

**Specs:** `spec/services/tasks/parse_ticket_refs_service_spec.rb` — single ticket, multi-ticket `&`, lowercase prefix, number-only input. **Spec written before implementation.**

**Done when:** Ticket refs shown on task. Bulk input parsed correctly.

---

#### B-09: Task search
**Goal:** Search across title and ticket refs. Foundation for Log Time autocomplete in B-11.

**Key files:** `app/services/tasks/search_query.rb`

**Key actions:**
- `Tasks::SearchQuery.call(query:, customer_id: nil, status: :active)` — SQLite LIKE on title + joined ticket refs
- Search field on task index (Turbo Frame — results update without full reload)
- Filter by customer, status, billable

**Specs:** `spec/services/tasks/search_query_spec.rb` — title match, ticket prefix+number match, customer filter, status filter, billable filter. **Spec written before implementation.**

**Done when:** Search returns correct results for title and ticket number inputs.

---

### Phase 4 — Log Time (S-04)

#### B-10: TimeEntry model
**Goal:** Core time entry model with all constraints.

**Key files:** `app/models/time_entry.rb`, migration

**Key actions:**
- Columns: task_id, invoice_id (nullable), date (date type), hours decimal(4,1), notes
- **Migration: unique index on `[task_id, date]`, index on `task_id`, index on `invoice_id`.**
- Validation: hours must be multiple of 0.5, positive
- `TimeEntry.log(task:, date:, hours:)` — increments existing or creates new
- Update task show page (B-07) to show total hours and time entries list now that the model exists

**Specs:** `spec/models/time_entry_spec.rb` — 0.5 validation, upsert behaviour, unique constraint, `TimeEntry.log` increments correctly.

**Done when:** `TimeEntry.log` increments on same-day duplicate. 0.3h rejected. Task show page shows total hours.

---

#### B-11: Log Time — entry form + preview
**Goal:** Entry form at top of Log Time screen with live preview panel.

**Note:** This is the largest "Medium" chunk — it covers route setup, Stimulus date picker, autocomplete wiring (B-09), Turbo Frame preview with running-total logic, create path, and Turbo Stream form reset. If it runs long, split after the create path works and do the live preview as a follow-on.

**Key files:** `app/controllers/time_entries_controller.rb`, `app/views/time_entries/`, `app/javascript/controllers/time_entry_form_controller.js`

**Key actions:**
- Route: `GET /log` → Log Time screen, set as root after auth
- Form: Stimulus date-picker controller, task search/autocomplete (wires to `Tasks::SearchQuery`), hours input
- Preview Turbo Frame (`GET /time_entries/preview`): shows task name/customer/project code + "Already Xhr today → adding Y → total: Zh" message (must look up existing `[task_id, date]` entry)
- `POST /time_entries` → `TimeEntry.log` → Turbo Stream: updates log below, resets form (date persists, task clears)

**Specs:** `spec/requests/time_entries_spec.rb` — preview endpoint (existing entry, new entry), create, upsert increments hours.

**Done when:** Form shows preview. Save creates/updates entry. Form resets after save.

---

#### B-12: Log Time — inline task creation
**Goal:** "Create task" expansion in search dropdown when no match found.

**Key files:** inline action on `app/controllers/tasks_controller.rb`, `app/views/tasks/_inline_form.html.erb`

**Key actions:**
- No results → "Create task" option in dropdown (Turbo Frame)
- Inline form: title pre-filled, customer select (needs B-05), project code select (needs B-06)
- Save → creates task, Turbo Stream auto-selects it in the entry form

**Specs:** `spec/requests/tasks_spec.rb` — inline create, auto-selects on success.

**Done when:** Unknown task name → create option appears. Created task auto-selects.

---

#### B-13: Log Time — history log
**Goal:** Last 14 days below the entry form, grouped by date. Empty days visible.

**Key files:** `app/services/time_entries/recent_log_query.rb`, `app/views/time_entries/_log.html.erb`

**Key actions:**
- `TimeEntries::RecentLogQuery.call(days: 14)` — entries grouped by date, fills in empty days as explicit groups
- Each row: task title, hours, project code, billed/unbilled badge, ✎ edit button
- Each group: date header with daily total, `[ + Add entry ]` link (pre-fills date in top form)

**Specs:** `spec/services/time_entries/recent_log_query_spec.rb` — correct grouping, empty day generation, date range boundaries. **Spec written before implementation.**

**Done when:** 14-day log renders below form. Empty days visible. `[ + Add entry ]` pre-fills date.

---

#### B-14: Log Time — inline editing + soft lock
**Goal:** Edit hours/date inline. Soft-lock warning for billed entries.

**Key files:** edit/update/destroy on `app/controllers/time_entries_controller.rb`, `app/views/time_entries/_entry_row.html.erb`

**Key actions:**
- ✎ click → inline edit form replaces row (Turbo Stream)
- Save → row updates in place, day total recalculates (Turbo Stream)
- Billed entry (`invoice_id` set): confirmation dialog before edit or delete
- Delete unbilled entry with confirmation

**Note on specs:** Billed-entry fixtures are constructed directly (factory with `invoice_id: 99` — a fabricated ID). A full integration test exercising a real finalized invoice belongs in B-23.

**Specs:** `spec/requests/time_entries_spec.rb` — update hours, update date, delete unbilled, billed edit returns warning, billed delete returns warning.

**Done when:** Inline edit saves without page reload. Billed entries show warning. Delete works.

---

### Phase 5 — Data Import (S-06)

#### B-15: Import parser
**Goal:** Parse Excel work log format into structured data.

**Key files:** `app/services/import/parse_log_service.rb`

**⚠ Decide the date-derivation rule before writing the spec:** The input format uses row-position dates ("each line = one day, rows are sequential"). Confirm whether an explicit date header line is also supported, and what day-zero is. This must be resolved before the spec can be written.

**Input format:**
```
- AW-6522 DesignRequest Polymorphic Refactor (5), Meetings (1), Deploy prep (0.5)
- AW-6770 & AW-6771 Disable & Remove Autodesign (1.5)
```

**Specs:** `spec/services/import/parse_log_service_spec.rb` — single item, multiple comma-separated items, multi-ticket `&`, half-hours `(0.5)`, no hours, no ticket prefix, date derivation from row position. **Spec written before implementation.**

**Done when:** Parser handles all variants. Date derivation rule tested.

---

#### B-16: Import UI
**Goal:** Preview-before-commit import screen.

**Key files:** `app/controllers/imports_controller.rb`, `app/views/imports/`

**Note:** Scope risk — "adjust project code or fix task names before committing" is essentially an editable grid. Keep it simple: allow project code selection per parsed row only. Full inline name editing is a stretch goal; mark it explicitly if time runs short.

**Key actions:**
- Paste raw text → parse (B-15) → preview table (proposed TimeEntries with matched/new Task, project code select per row)
- Duplicate detection: skips existing `[task_id, date]` pairs
- Commit → import report (X entries created, Y skipped, Z tasks created)

**Specs:** `spec/services/import/commit_service_spec.rb` (service-level: duplicate skip, task creation, entry creation) + `spec/requests/imports_spec.rb`.

**Done when:** Preview shows parsed data. Commit creates records. Duplicates skipped. Report shown.

---

### Phase 6 — Reports (S-07)

#### B-17: Report — Monthly Hours by Project Code
**Goal:** Invoice-prep report. Customer + date range → project code breakdown + grand total.

**Key files:** `app/services/reports/monthly_hours_query.rb`, `app/controllers/reports_controller.rb`, view

**Key actions:**
- `Reports::MonthlyHoursQuery.call(customer:, from:, to:)` → grouped by project code, using `time_entry.date`
- Grand total includes tasks without project code; project code chart excludes them
- CSV export

**Specs:** `spec/services/reports/monthly_hours_query_spec.rb` — correct totals, tasks without project code in total only.

**Done when:** Correct totals. Grand total includes all billable hours. CSV downloads.

---

#### B-18: Reports — Daily Log + Task Totals
**Goal:** The remaining two v1 reports.

**Key files:** `app/services/reports/daily_log_query.rb`, `app/services/reports/task_totals_query.rb`, views

**Key actions:**
- Daily log: date-grouped, filters by customer + date range, shows billed/unbilled
- Task totals: per-task summary, filters by customer/project code/status/billable

**Specs:** `spec/services/reports/daily_log_query_spec.rb`, `spec/services/reports/task_totals_query_spec.rb`.

**Done when:** Both reports render with all filters working.

---

### Phase 7 — Invoice Wizard (S-08)

#### B-19: Invoice model + wizard shell
**Goal:** Invoice record, wizard step routing, sequence seed.

**Key files:** `app/models/invoice.rb`, `app/models/invoice_line.rb`, `app/controllers/invoices/wizard_controller.rb`, migration

**Key actions:**
- Invoice columns per data model, including `wizard_current_step integer` (nullable — persists wizard progress for resume)
- **Migration: unique index on `sequence_number`, index on `customer_id`, index on `status`.**
- `InvoiceLine` columns: invoice_id, description, sort_order, task_ids (json). **Migration: index on `invoice_id`.**
- **Sequence seed: insert one invoice row with `sequence_number: 316` then delete it (or use `sqlite_sequence` update) so the auto-increment starts at 317 — meaning the first real invoice gets `sequence_number: 316`.** Document the exact mechanism.
- `Invoice.next_sequence_number` — allocates inside a DB transaction
- `invoice_number` derived from `sequence_number` + `customer.invoice_prefix`
- Wizard controller: `step` param routes to correct partial; updates `wizard_current_step` on each advance
- Progress bar component

**Specs:** `spec/models/invoice_spec.rb` — `invoice_number` derivation, status transition guards (illegal transitions rejected), `next_sequence_number` uniqueness. **Status transition spec: verify `draft→ready`, `ready→sent`, `sent→paid` are valid; verify `draft→sent`, `ready→paid`, backwards transitions are invalid.**

**Done when:** Draft invoice creates. `invoice_number` is `ARGEN-0316` for `sequence_number: 316`. Wizard shell renders step 1. `wizard_current_step` persists on advance.

---

#### B-20: Wizard steps 1–2 (customer + entries review)
**Goal:** Pick customer + date range. Review un-billed entries.

**Key files:** `app/services/invoices/unbilled_entries_query.rb`, step 1 + 2 views

**Key actions:**
- Step 1: customer select, date range picker, rate auto-populated from `CustomerRate.current_for(customer, period_start)`
- Step 2: all billable un-billed TimeEntries for customer in range, grouped by task, total hours shown. Warning if any entry is already on a sent invoice.
- Advance updates `wizard_current_step`

**Specs:** `spec/services/invoices/unbilled_entries_query_spec.rb` — correct filtering (billable only, invoice_id nil, date range, customer).

**Done when:** Steps 1–2 navigate correctly. Entries table shows correct billable totals.

---

#### B-21: Wizard steps 3–4 (craft lines + LLM placeholder)
**Goal:** Write/edit invoice description lines. LLM placeholder.

**Key files:** `app/controllers/invoices/lines_controller.rb`, step 3 + 4 views

**Key actions:**
- Step 3: add/edit/delete/reorder description lines. Each line: description text + optional task selector (task_ids stored as JSON). Drag-to-reorder via Stimulus + `sort_order` update endpoint.
- Step 4: "Generate descriptions" button — returns placeholder message ("LLM not configured") until B-25

**Specs:** `spec/requests/invoices/lines_spec.rb` — create, update, delete, reorder (sort_order updates correctly).

**Done when:** Lines created/edited/deleted/reordered. Step 4 renders placeholder.

---

#### B-22: Wizard steps 5–6 (preview + finalize)
**Goal:** Preview rendered invoice. Finalize — snapshot totals, stamp TimeEntries.

**Key files:** `app/services/invoices/finalize_service.rb`, step 5 + 6 views

**Key actions:**
- Step 5: rendered preview — description lines + project summary (if `customer.requires_project_codes`) + total hours + amount due
- `Invoices::FinalizeService.call(invoice:)`:
  1. If `customer.requires_project_codes`: validate all billable entries have a project code — raise/return error if not (don't silently skip)
  2. Compute `total_hours` = SUM of all billable TimeEntries in the selected set
  3. Stamp all included TimeEntries with `invoice_id`
  4. Snapshot `total_amount = total_hours × invoice.rate`
  5. Set `status: ready`, assign `invoice_number`
  6. Set `wizard_current_step: 6`

**Specs:** `spec/services/invoices/finalize_service_spec.rb` — correct total, TimeEntry stamping, invoice_number assigned, `requires_project_codes` blocks finalization when tasks lack project codes, `requires_project_codes: false` succeeds with unassigned tasks. **Spec written before implementation.**

**Done when:** Finalize snapshots correct totals. TimeEntries stamped. `invoice_number` assigned. Project code enforcement tested.

---

#### B-23: Invoice lifecycle (sent → paid)
**Goal:** Mark sent, mark paid. Timestamps, soft-lock enforcement, integration smoke test.

**Key files:** `app/controllers/invoices_controller.rb` (status actions), `app/views/invoices/`

**Key actions:**
- Invoice index with status badges, quick links (open wizard for drafts, show for sent/paid)
- "Mark as Sent" → confirmation → `sent_at = Time.current`, `status: sent`
- "Mark as Paid" → `paid_at = Time.current`, `status: paid`
- Soft-lock for TimeEntry edits now exercises a real invoice (integration check for B-14's billed-entry path)

**Specs:** `spec/requests/invoices_spec.rb` — sent transition sets `sent_at`, paid transition sets `paid_at`, illegal transitions rejected.

**Done when:** Full lifecycle works end to end. Integration: finalize an invoice, mark sent, confirm TimeEntry edit shows warning.

---

### Phase 8 — LLM Integration (S-09)

#### B-24: LlmClient service
**Goal:** Configurable, tested LLM client.

**Key files:** `app/services/llm_client.rb`

**⚠ Get access to OpenClaw codebase before starting. Extract the existing pattern — do not rebuild from scratch.**

**Key actions:**
- `LlmClient.new(endpoint:, model:, timeout:)` — reads `LLM_ENDPOINT`, `LLM_MODEL`, `LLM_TIMEOUT` from ENV by default
- `.complete(prompt:)` → string or raises `LlmClient::Error`
- Timeout + connection errors caught and re-raised as `LlmClient::Error`
- Must not be called inside a DB transaction

**Specs:** `spec/services/llm_client_spec.rb` — stubbed HTTP: success path, timeout, connection refused, unexpected status code. **Spec written before implementation.**

**Done when:** Client works against local Qwen endpoint. All error paths covered with stubs.

---

#### B-25: InvoiceDescriptionGenerator + wizard wiring
**Goal:** Wire LLM into wizard step 4. Generate description suggestions per line.

**Key files:** `app/services/invoices/description_generator_service.rb`

**⚠ Few-shot prompt design requires sample invoice PDFs from the user — resolve before starting this chunk.**

**Key actions:**
- `Invoices::DescriptionGeneratorService.call(invoice_lines:)` — builds prompt from task titles/invoice_name/ticket refs/notes, calls `LlmClient`, returns suggestions keyed by line
- Step 4: "Generate" fires service, populates blank descriptions via Turbo Stream per line
- Error handling: `LlmClient::Error` → show error per line, lines stay editable, wizard continues unblocked

**Specs:** `spec/services/invoices/description_generator_service_spec.rb` — stubbed `LlmClient`: success populates descriptions, `LlmClient::Error` returns per-line error, does not block wizard.

**Done when:** Generate populates descriptions. LLM failure doesn't block wizard.

---

## Summary

| Chunk | Story | Phase | Complexity |
|-------|-------|-------|------------|
| B-00 | —    | App Setup | Small |
| B-01 | S-01 | Foundation | Small |
| B-02 | S-01 | Foundation | Small |
| B-03 | S-01 | Foundation | Small |
| B-04 | S-01 | Foundation | Small |
| B-05 | S-02 | Customers | Small |
| B-06 | S-02 | Customers | Medium |
| B-07 | S-03 | Tasks | Small |
| B-08 | S-03 | Tasks | Medium |
| B-09 | S-03 | Tasks | Small |
| B-10 | S-04 | Log Time | Small |
| B-11 | S-04 | Log Time | Large |
| B-12 | S-04 | Log Time | Medium |
| B-13 | S-04 | Log Time | Medium |
| B-14 | S-04 | Log Time | Medium |
| B-15 | S-06 | Import | Medium |
| B-16 | S-06 | Import | Medium |
| B-17 | S-07 | Reports | Small |
| B-18 | S-07 | Reports | Small |
| B-19 | S-08 | Wizard | Medium |
| B-20 | S-08 | Wizard | Medium |
| B-21 | S-08 | Wizard | Medium |
| B-22 | S-08 | Wizard | Medium |
| B-23 | S-08 | Wizard | Small |
| B-24 | S-09 | LLM | Medium |
| B-25 | S-09 | LLM | Medium |

**26 chunks total.** S-05 merged into S-04. S-10/PDF, S-11/Docker, S-12/Backup deferred.
