# System Overview

## Purpose

A Rails app for a solo contractor to track daily work, log hours against tasks and Jira tickets, and generate monthly invoices for one or more clients. Replaces an Excel-based workflow (monthly tabs, 30-minute blocks, manual hour summing).

## Tech Stack

- **Backend:** Ruby on Rails 8.1.3 / Ruby 4.0.5
- **Frontend:** Turbo (Morphing/Frames/Streams) + Stimulus controllers. No inline scripts.
- **Database:** SQLite (3 files: primary, queue, cache)
- **Auth:** Single-password session login (ENV-configured)
- **LLM:** Local Qwen via llama REST API, wrapped in a `LlmClient` service object (pattern extracted from OpenClaw codebase). Graceful degradation — LLM features catch errors and show fallbacks.
- **PDF:** Deferred to a later story.

## Deployment

Initially: `rails server -b 192.168.1.x -p 3005` on a home network machine.

Later: Docker container with SQLite on a mounted host volume. Backups via cron → Google Drive / Dropbox.

## Core Philosophy

- This is a **log of work done**, not a time-tracking tool. No timers. Hours logged manually in 0.5-increment blocks, usually at end of day or retrospectively.
- **Tasks are the unit of work.** Time entries are logged against tasks. A task can span many months; billing is always by the invoice period (hours logged in that date window), not by task completion.
- **Everything logged gets billed** (unless explicitly marked `billable: false`, which is rare). The tracked total is the billed total.
- **Invoices are monthly snapshots.** An invoice captures all un-billed billable time entries for a customer in a date range. Tasks appear on as many invoices as they have hours in those periods.

## Key Workflows

### Daily Time Logging (Log Time screen)
The home screen after login. Entry form at top: task search/autocomplete, date picker (defaults to today), hours. Preview panel shows task details and running total before saving. After saving, form resets for the next entry.

Below the form: the last 14 days of entries grouped by date, most recent first. Empty days show explicitly so gaps are visible. Click any entry to edit inline. Click a date's `[ + Add entry ]` to pre-fill that date in the form above.

This single screen handles both new entries and editing/backdating past entries.

### End-of-Month Invoicing
Wizard: pick customer + date range → review all un-billed time entries (total hours shown) → craft description lines for the client (~15 curated lines from ~30 tracked tasks) → LLM-assisted description generation → preview rendered invoice → finalize.

The invoice has three sections:
1. **Line items** — client-facing descriptions only, no hours per line
2. **Project summary** — `Project Code | Description | Hours`, auto-computed from all TimeEntries grouped by project code (tasks without a project code contribute to the total but not this chart)
3. **Total** — `total_hours × rate = amount due`

`total_hours` is always the sum of all billable TimeEntries in the period, regardless of which tasks appear as line items.

## Invoicing Convention

- Invoices generated the month *after* the work period (March work → April invoice)
- Reports always filter by `time_entry.date` — the date work happened
- Invoice numbers: global sequential counter with customer prefix, e.g. `ARGEN-0316` (continuing from existing sequence at `0315`)
