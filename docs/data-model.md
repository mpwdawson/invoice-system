# Data Model

## Entity Relationships

```
ContractorProfile (one record — settings screen)

Customer
  ├── has_many :customer_rates       (rate history)
  ├── has_many :project_codes
  ├── has_many :tasks
  └── has_many :invoices

ProjectCode
  ├── belongs_to :customer
  └── has_many :tasks

Task
  ├── belongs_to :customer
  ├── belongs_to :project_code       (optional)
  ├── has_many :ticket_references
  └── has_many :time_entries

TicketReference
  └── belongs_to :task

TimeEntry
  ├── belongs_to :task
  └── belongs_to :invoice            (optional — nil = un-billed)

Invoice
  ├── belongs_to :customer
  └── has_many :invoice_lines

InvoiceLine
  └── belongs_to :invoice            (description-only — no task FK)
```

---

## Tables

### contractor_profiles
One row. Edited via Settings screen. Enforced as singleton via `first_or_initialize` in the controller.

| Column | Type | Notes |
|--------|------|-------|
| name | string | Your trading name |
| address | text | Multi-line |
| email | string | |
| tax_number | string | ABN, GST, etc. Displayed on invoice header |
| bank_details | text | Payment instructions for invoice footer |

---

### customers

| Column | Type | Notes |
|--------|------|-------|
| name | string | |
| address | text | Appears on invoice header |
| contact_name | string | |
| contact_email | string | |
| invoice_prefix | string | optional. e.g. `ARGEN` → invoice numbers like `ARGEN-0316`. If blank, falls back to just the padded sequence: `0316`. |
| requires_project_codes | boolean | Whether invoice PDF includes project summary section |

**Currency:** Single-currency assumption (USD) in v1. No currency field. Document if a second customer introduces multi-currency.

**Tax:** No tax calculation in v1. `tax_number` on ContractorProfile is displayed on invoice for compliance. Tax rates and line-item tax math are a future story.

---

### customer_rates
Rate history per customer. A new row is added each time the rate changes.

| Column | Type | Notes |
|--------|------|-------|
| customer_id | integer | |
| rate | decimal(10,2) | $/hr. Use decimal(10,2) throughout for money — never float. |
| effective_from | date | First date this rate applies |

At invoice creation, the system looks up the rate effective for `period_start` and stamps it onto the invoice.

`CustomerRate.current_for(customer, date)` — class method returning the effective rate for a given date.

---

### project_codes

| Column | Type | Notes |
|--------|------|-------|
| customer_id | integer | |
| code | string | e.g. `DSNSERV`, `INFRAWEB` |
| description | string | e.g. `Design Services Phase 1` |
| active | boolean | Archived codes hidden from entry UI but preserved on historical data |

`requires_project_codes` on Customer is enforced at **invoice finalization** (not task creation) — so the data import and task creation flows are never blocked.

---

### tasks

| Column | Type | Notes |
|--------|------|-------|
| customer_id | integer | |
| project_code_id | integer | nullable |
| title | string | Raw working title, e.g. `AW-6522 DesignRequest Polymorphic Refactor` |
| invoice_name | string | nullable — LLM-suggested description, used as starting material when building invoice lines |
| notes | text | nullable — internal context |
| status | string | `active` / `archived` |
| billable | boolean | default `true`. When `false`, time entries are tracked but excluded from invoice totals and project summary. Optional, rarely used. |

**Tasks do not cross customers.** A task always belongs to one customer. If the same work spans customers, create separate tasks per customer.

---

### ticket_references
A task can reference zero, one, or many Jira/project tickets.

| Column | Type | Notes |
|--------|------|-------|
| task_id | integer | |
| prefix | string | e.g. `AW`, `QAD`, `IA` |
| number | integer | e.g. `6522` |

Unique index on `[task_id, prefix, number]`.

---

### time_entries

| Column | Type | Notes |
|--------|------|-------|
| task_id | integer | |
| invoice_id | integer | nullable — stamped when the entry is included in a finalized invoice |
| date | date | Work date. Always a `date` type, never `datetime`. No timezone coercion. |
| hours | decimal(4,1) | Must be a multiple of 0.5 |
| notes | text | nullable |

**Unique index on `[task_id, date]`** — one entry per task per day. Adding hours on the same task+date updates (increments) the existing entry. This is intentional: it prevents duplicate entries and allows easy review/correction.

**Deletion rules:**

| Entry state | Behaviour |
|---|---|
| Un-billed (`invoice_id: nil`) | Delete freely with confirmation dialog |
| Billed (`invoice_id` set) | Soft lock — warning: *"This entry is on invoice ARGEN-0316 (sent). Delete anyway?"* Allowed after confirmation. Deleting does not change the sent invoice — `Invoice.total_hours` is snapshotted at finalization. |

**Missed-hours corrections:** To add hours missed from a previous period, create a TimeEntry for a task like `"Billing correction — October shortfall"` with the current period's date. It rolls into the total automatically. No separate "adjustment" mechanism needed.

---

### invoices

| Column | Type | Notes |
|--------|------|-------|
| customer_id | integer | |
| sequence_number | integer | Auto-incremented global integer. Source of truth for ordering. |
| invoice_number | string | Derived display string: `"#{prefix}-#{seq.rjust(4,'0')}"` if prefix set (e.g. `ARGEN-0316`), else just `"0316"`. |
| period_start | date | |
| period_end | date | |
| status | string | `draft` → `ready` → `sent` → `paid` |
| rate | decimal(10,2) | Stamped from `CustomerRate` at creation. Immutable. |
| total_hours | decimal(6,1) | Snapshotted at finalization = SUM of included billable TimeEntries |
| total_amount | decimal(10,2) | Snapshotted at finalization = total_hours × rate |
| sent_at | datetime | nullable — set when status changes to `sent` |
| paid_at | datetime | nullable — set when status changes to `paid` |
| wizard_current_step | integer | nullable — persists wizard progress (1–6) so the user can resume mid-wizard after a page reload |
| notes | text | nullable — internal notes |

**Seeding:** `sequence_number` is seeded at `316` — meaning the first invoice created will be `ARGEN-0316` (continuing from the last manually issued invoice `0315`). Seeded in a migration, not `seeds.rb`, so it runs automatically on first deploy. The seed sets the SQLite auto-increment starting point via a single `INSERT` with `sequence_number: 316` then `DELETE` (or via a migration that sets the sqlite_sequence row directly).

**Invoice number uniqueness:** Unique index on `sequence_number`. `invoice_number` is a derived virtual attribute or a stored string updated before save.

**Status behavior:**
- `draft`: line items editable, time entries still accruing
- `ready`: reviewed, locked. `total_hours` and `total_amount` snapshotted. PDF can be generated.
- `sent`: `sent_at` stamped. Soft lock on time entries. All included TimeEntries have `invoice_id` set.
- `paid`: `paid_at` stamped. Final state.

---

### invoice_lines

Invoice lines are **client-facing narrative descriptions only**. They do not carry hours. The client sees what the work *was*, not how long each item took.

| Column | Type | Notes |
|--------|------|-------|
| invoice_id | integer | |
| description | string | Client-visible line, e.g. `"Added Rewards Customer Dashboard"` |
| sort_order | integer | For reordering |
| task_ids | json | nullable — array of Task IDs used as context for LLM generation. Internal only, not displayed. |

**No hours on invoice lines.** The total hours come from `Invoice.total_hours` (computed from TimeEntries at finalization).

**No project_code on invoice lines.** The project summary is a separate computed section — see below.

---

## Invoice Structure (what the client sees)

```
[Header]
  Invoice number, date, contractor details, client details

[Line Items — descriptions only]
  Added Rewards Customer Dashboard
  Refactored Design Request data model
  Removed AutoDesign functionality
  ...

[Project Summary — customers with requires_project_codes: true]
  Project Code | Description          | Hours
  DSNSERV      | Design Services Ph1  | 45
  INFRAWEB     | Rails Upgrades       | 22
  (Tasks without project codes contribute to total but not this chart)

[Total]
  Total Hours: 200
  Rate: $X/hr
  Amount Due: $Y
```

The project summary is **computed at render time** from TimeEntries stamped with this invoice's ID, grouped by `task.project_code`. Since TimeEntries are immutable once stamped, this always produces the correct historical result.

---

## Invoice Numbering

- `sequence_number` is a plain incrementing integer stored on the invoice
- Display string: `"#{prefix}-#{seq.rjust(4,'0')}"` if customer has a prefix (e.g. `ARGEN-0316`); otherwise just the padded number (e.g. `0316`)
- Counter is global across all customers — one sequence, different prefixes
- Starting value: 316 (seeded in migration, continuing from existing invoice #0315)
- Unique index on `sequence_number` — allocated inside a DB transaction to prevent races

---

## Time Zones

- **Database:** UTC for all `datetime` columns (`sent_at`, `paid_at`, `created_at`, `updated_at`)
- **App config:** `config.time_zone = "Pacific Time (US & Canada)"`
- **Work dates:** Stored as `date` type (no time component, no timezone). A date is a date — no coercion through `Time.zone`.

---

## Key Queries

**Un-billed time entries for a customer in a date range (invoice wizard):**
```sql
SELECT time_entries.*
FROM time_entries
JOIN tasks ON tasks.id = time_entries.task_id
WHERE tasks.customer_id = ?
  AND tasks.billable = true
  AND time_entries.date BETWEEN ? AND ?
  AND time_entries.invoice_id IS NULL
```

**Invoice total hours at finalization:**
```sql
SELECT SUM(time_entries.hours)
FROM time_entries
JOIN tasks ON tasks.id = time_entries.task_id
WHERE time_entries.invoice_id = ?
  AND tasks.billable = true
```

**Project summary for invoice:**
```sql
SELECT project_codes.code, project_codes.description, SUM(time_entries.hours)
FROM time_entries
JOIN tasks ON tasks.id = time_entries.task_id
JOIN project_codes ON project_codes.id = tasks.project_code_id
WHERE time_entries.invoice_id = ?
  AND tasks.billable = true
  AND tasks.project_code_id IS NOT NULL
GROUP BY project_codes.id
```

**Total hours for a task (all time — task drill-down report):**
```sql
SELECT SUM(hours) FROM time_entries WHERE task_id = ?
```

**Monthly hours by project code (report):**
```sql
SELECT project_codes.code, project_codes.description, SUM(time_entries.hours)
FROM time_entries
JOIN tasks ON tasks.id = time_entries.task_id
JOIN project_codes ON project_codes.id = tasks.project_code_id
WHERE tasks.customer_id = ?
  AND tasks.billable = true
  AND time_entries.date BETWEEN ? AND ?
  AND tasks.project_code_id IS NOT NULL
GROUP BY project_codes.id
```

**Note:** All reports use `time_entry.date` — the date work happened. Never the invoice date or creation date.
