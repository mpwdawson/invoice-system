# Design Decisions

Key decisions and rationale. These represent the "why" behind the data model and UX choices.

---

## Tasks + TimeEntries (not flat entries)

**Decision:** Tasks are first-class entities. Time entries are logged *against* a task.

**Why:** A single ticket like `AW-6522` was worked on across many days over weeks. With flat entries you'd have to manually sum those to find total hours. Tasks give you a canonical identity for a piece of work, with accumulated time across the whole project.

---

## Ticket References as Separate Records

**Decision:** Jira/project ticket numbers are stored as `TicketReference` rows (prefix + number), not as a text field on the task.

**Why:** Multi-ticket entries like `AW-6770 & AW-6771` are common. Two TicketReference rows on one Task handles this cleanly. Making them queryable rows also allows filtering by ticket number and auto-linking to the correct app/prefix system.

---

## Task Owns Customer Directly

**Decision:** `Task belongs_to :customer` directly, with `project_code` as optional metadata.

**Why:** Not all tasks have project codes (`Meetings`, `QA Support`, `Deploy prep`). If customer was inferred through project code, these tasks would have no owner. Direct ownership on Task makes "all tasks for Customer X this month" a trivial query.

---

## One TimeEntry Per Task Per Day

**Decision:** Unique index on `[task_id, date]`. Logging more hours on the same task+day updates (increments) the existing entry rather than creating a second row.

**Why:** The mental model is "I worked N hours on this task today." The unique constraint prevents accidental double-entry (double-click, Turbo retry) and makes review/editing straightforward — one row to find and edit, not multiple to hunt through. Double-submission risk is handled at the form layer (disable submit after click).

**UX implication:** Quick-entry preview shows "already logged 0.5hrs today → adding 1.5 → new total: 2.0hrs."

---

## Invoice Lines Are Descriptions Only — No Hours Per Line

**Decision:** `InvoiceLine` has a `description` field and a `sort_order`. No `hours` column. No task FK required.

**Why:** The client invoice shows what work was done, not how long each item took. The user tracks 30 tasks internally but shows ~15 curated description lines to the client. These lines are a narrative summary, not a 1:1 breakdown of every logged task. Hours are irrelevant at the line level — only the total matters.

**Implication:** The LLM generates description text from task context (`task_ids` stored as JSON on InvoiceLine for reference). The invoice total comes from TimeEntries, not from summing line item hours (there are none).

---

## Invoice Total Always From TimeEntries

**Decision:** `Invoice.total_hours` is computed (and snapshotted at finalization) from the SUM of all billable TimeEntries stamped with that invoice's ID. Never from InvoiceLine data.

**Why:** Invoice lines are curated narrative — they don't cover every task 1:1. The real billing number is "all hours worked and logged this period." This means every logged, billable hour gets billed, even if it doesn't appear as its own invoice line (e.g. meetings, small bug fixes grouped into a summary line or left off the narrative entirely).

---

## Project Summary Is Computed, Not Stored as Lines

**Decision:** The `Project Code | Description | Hours` section on the invoice is computed at render time from TimeEntries grouped by `task.project_code`. Not stored as InvoiceLines.

**Why:** This section shows accurate project hour totals from the actual time log. Since TimeEntries are stamped immutably with `invoice_id` at finalization, the computation always returns the correct historical result. Tasks without a project code (Meetings, etc.) contribute to the total but not this chart — intentionally.

---

## Task.billable Flag

**Decision:** `Task.billable boolean, default true`. Non-billable tasks are tracked but excluded from invoice totals and project summaries.

**Why:** Occasionally useful for logging overhead or internal work that won't be charged. Rare but worth supporting as a simple flag rather than requiring workarounds. Default true means zero behavior change for normal usage.

---

## invoice_name Stays Blank Until Invoice Time

**Decision:** `Task.invoice_name` is null by default. Used as starting material when building invoice line descriptions. Not required at task creation.

**Why:** Task titles evolve as work progresses. The invoice description is only relevant at billing time. The LLM bulk-generates suggestions from task context during the invoice wizard; the user reviews and edits.

---

## Rate History + Stamped Rate on Invoice

**Decision:** Two-layer rate model: `CustomerRate` table (history with `effective_from` dates) + `rate` and `total_amount` columns on Invoice (stamped at finalization, immutable).

**Why:** Rates change over time. Historical invoices must always reflect the rate that was actually charged. The history table auto-populates new invoices; the stamped values protect historical accuracy.

---

## Sequence Number Column for Invoice Numbering

**Decision:** `Invoice.sequence_number` is a plain integer column. The display string (`ARGEN-0316`) is derived from it. Starting value: 316 (continuing from existing sequence at 0315).

**Why:** Deriving the sequence by parsing `MAX(invoice_number)` strings is fragile. An integer column is a clean, indexable, incrementable source of truth. The display format is presentation logic, not schema.

**Prefix is optional:** `Customer.invoice_prefix` is optional. When present, the invoice number is `#{prefix}-#{seq.rjust(4,'0')}` (e.g. `ARGEN-0316`). When absent, the invoice number is just the padded sequence (e.g. `0316`).

**Note:** The user has 10 years of history with their existing sequential numbering and has had no tax issues with it. The global sequence (not per-customer) with customer prefix is intentional and proven.

---

## sent_at / paid_at Timestamps

**Decision:** `Invoice` has `sent_at` and `paid_at` datetime columns (nullable), set when status transitions occur.

**Why:** "When was this sent?" and "When did they pay?" are real questions. Enables aging reports, outstanding invoice tracking, and eventual overdue logic. Free columns to add now, expensive to retrofit later.

---

## Soft Lock on Sent Invoices

**Decision:** Editing or deleting time entries that belong to a sent invoice shows a warning but is not blocked.

**Why:** Solo user, local app. Hard locks create friction when catching a typo after sending. The `Invoice.total_hours` and `Invoice.total_amount` snapshots already protect the billed amounts — the actual numbers charged to the client never change even if underlying entries are corrected.

---

## Invoice Wizard (Not Automatic Generation)

**Decision:** Invoices are created through a guided linear wizard — one step per page with a progress bar, Back/Next navigation, state persisted to the invoice record between steps: customer → date range → review entries → craft lines → LLM names → preview → finalize.

**Why:** Date ranges vary (sometimes 2 weeks, not a full month). Line items require human curation (the client sees ~15 lines, not all 30 tracked tasks). The LLM name generation needs a confirmation step. Linear steps keep focus — you can't accidentally skip finalization.

---

## Reports Always Use time_entry.date

**Decision:** All reports filter and group by `time_entry.date` — the date work happened. Never by invoice date, creation date, or "today."

**Why:** Invoices are generated the month *after* the work happens (March work → April invoice). Reports must reflect when work was done, not when it was billed. "March hours" means time entries with dates in March, regardless of which invoice they ended up on.

---

## Quick Entry: Inline Task Creation

**Decision:** When a task search returns no match, show a "Create task" inline expansion within the search dropdown (Turbo Frame). Pre-fills the title from the search text. Requires customer selection + optional project code before saving. After creation, auto-selects the new task and moves focus to the hours field — no page navigation needed.

**Why:** New tickets arrive mid-sprint. Forcing navigation away from the quick-entry screen to create a task first breaks the daily logging flow. The inline path adds a small amount of build complexity (S-04) but protects the zero-friction daily habit.

---

## No Timer Feature

**Decision:** No built-in timer. Hours are always entered manually.

**Why:** Forgetting to stop timers is an explicit pain point. The app is designed for retrospective logging. The quick-entry screen with date picker supports logging time for any past date.

---

## Time Zones

**Decision:** `datetime` columns stored in UTC. `config.time_zone = "Pacific Time (US & Canada)"`. Work dates stored as `date` type — no time component, no timezone coercion.

**Why:** Standard Rails practice. Work dates are calendar dates ("I worked on the 3rd"), not moments in time — using `date` columns prevents any TZ conversion from shifting a date unexpectedly.

---

## No Tax in v1

**Decision:** No tax rates, tax lines, or tax math in v1. `ContractorProfile.tax_number` is displayed on the invoice for compliance purposes only.

**Why:** Current invoicing practice doesn't include tax line items. Tax support is a future story when requirements are clearer (GST, VAT, sales tax rules vary by jurisdiction and client).

---

## Missed-Hours Corrections Are TimeEntries

**Decision:** When under-billing is discovered and hours need to be added to a future invoice, create a TimeEntry on a correction task (e.g. `"Billing correction — October shortfall"`) with the current period's date.

**Why:** No separate "adjustment" mechanism needed. The correction rolls into the total naturally. The notes field on the task or entry captures the context. This matches the user's existing practice of adding hours to the next invoice.

---

## UI Layout & Design

**Decision:** Fixed left sidebar navigation, collapsible on mobile. Dark mode supported via Tailwind `class` strategy. No custom branding — personal tool.

**Nav structure (workflow order):** App name at top + dark mode toggle, links for: Log Time / Tasks / Project Codes / Customers / Import / Reports / Invoices / Settings. Ordered by frequency of use / billing cycle flow, not alphabetically.

**Home screen:** Login redirects directly to Log Time. No separate dashboard.

**Dark mode implementation:** Tailwind `darkMode: 'class'` in config. A Stimulus controller toggles the `dark` class on `<html>` and persists the preference to `localStorage`. No server-side preference storage needed.

**Mobile:** Sidebar slides in as an overlay below `md:` breakpoint (hamburger button top-left). Tasks index hides secondary columns below `sm:`. Log Time form goes full-width below `sm:`. Responsive support added in M-01–M-04.

**Why:** Sidebar gives instant one-click access to all sections. No dashboard — the daily log screen is where you spend 95% of your time, so go there directly. Dark mode is a daily-use quality-of-life feature. Neutral Tailwind slate/gray palette — no custom branding needed for a personal tool.

---

## Open Design Questions (to resolve when building those stories)

- ~~**Editing previous days UX**~~ **Resolved:** Combined screen — quick-entry form at top, scrollable date-grouped log below it (last 14 days). Empty days shown explicitly with a `[ + Add entry ]` prompt so gaps are visible. No separate History screen — one sidebar entry covers both entry and editing. Merges S-04 and S-05 into one screen.
- ~~**Import parsing logic (S-06/B-15, not S-04)**~~ **Resolved:** Quick entry (S-04) takes structured input — task search field + hours; there is no free-text parsing there. The parsing question is scoped entirely to **data import** (S-06): exact rules for extracting ticket refs, task titles, and hours from the pasted log. The date-derivation question is moot — a real June 2026 export confirms each row carries an explicit `Date` column (`M/D/YYYY`); no row-position inference or day-zero rule is needed. Write `Import::ParseLogService` from scratch — the original parse scripts have been deleted.
- **Invoice PDF format:** Per-customer template system. Primary customer requires project summary section. Deferred — requires sample PDFs as spec input. Resolve before S-10.
- **LLM prompt design:** Context sent with task titles to generate invoice line descriptions. User has old invoices as few-shot examples. Resolve when building S-09.
- **Per-customer invoice formats:** Different customers may have different invoice structures (line items with hours, different sections, etc.). `requires_project_codes` is the first such flag. A strategy pattern for invoice rendering is a future story.
