# Workflows

---

## 1. Log Time Screen (daily entry + history — combined)

The home screen after login. Handles both logging new hours and editing/backdating past entries.

```
┌─────────────────────────────────────────────────────────────┐
│  Log Time                                                   │
│                                                             │
│  Date: [ Jun 5, 2026 ]  [Today]                            │
│  Task: [ AW-6522... ]   ← search/autocomplete              │
│  Hours:[ 1.5       ]                                        │
│                                                             │
│  ┌──────────────────────────────────────┐                  │
│  │ Preview (Turbo Frame)                │                  │
│  │ Task:     AW-6522 DesignRequest...   │                  │
│  │ Customer: Argen  Project: INFRAWEB   │                  │
│  │ Already 0.5h today → total: 2.0h    │                  │
│  └──────────────────────────────────────┘                  │
│                                           [ Log Hours ]    │
├─────────────────────────────────────────────────────────────┤
│  ▼ Jun 5 (Thu) — Today                          5.5h       │
│    AW-6761 Hatch Product API        3.5h  [unbilled]  ✎   │
│    Meetings                         2.0h  [unbilled]  ✎   │
│  [ + Add entry ]                                           │
├─────────────────────────────────────────────────────────────┤
│  ▼ Jun 4 (Wed)                                  8.0h       │
│    AW-6522 DesignRequest Refactor   5.0h  [unbilled]  ✎   │
│    Deploy prep                      3.0h  [unbilled]  ✎   │
│  [ + Add entry ]                                           │
├─────────────────────────────────────────────────────────────┤
│  ▼ Jun 3 (Tue)                                  0.0h       │
│    (nothing logged)               ← gap visible            │
│  [ + Add entry ]                                           │
└─────────────────────────────────────────────────────────────┘
```

**Task search flow:**
```
Type in task field
       │
  ┌────┴─────┐
  │          │
Found      Not found
  │          │
  ▼          ▼
Select    "Create task" expands inline (Turbo Frame)
task      → title pre-filled, pick customer + project code
  │          │ [Save new task]
  └────┬─────┘
       │
       ▼
  Preview panel updates (Turbo Frame)
       │
       ▼ [Log Hours]
       │
  TimeEntry upsert [task_id, date]
  hours += 1.5
       │
       ▼ (Turbo Stream)
  Entry row appended/updated in log below ✓
```

**Editing past entries:**
- Click ✎ on any row → inline edit form for hours and/or date (Turbo Stream)
- Click `[ + Add entry ]` under a past date → pre-fills that date in the form at top
- Billed entry (has `invoice_id`) → soft-lock warning before edit/delete, allowed after confirmation

---

## 2. Monthly Invoice Wizard

Run once a month (or per billing cycle). Generates the client invoice.

```
STEP 1 ── Customer + Date Range
│
│  Customer:    [ Argen          ▼ ]
│  Period:      [ Jun 1, 2026 ] → [ Jun 30, 2026 ]
│  Rate:        $X/hr  (auto-populated from CustomerRate)
│
▼
STEP 2 ── Review Un-billed Time Entries
│
│  Showing all billable TimeEntries for Argen, Jun 1–30
│  with invoice_id: nil
│
│  Task                              Hours    Project
│  ─────────────────────────────────────────────────
│  AW-6522 DesignRequest Refactor    15.0h    INFRAWEB
│  AW-6761 Hatch Product API          7.0h    DSNSERV
│  AW-6770 Disable AutoDesign         1.5h    DSNSERV
│  Meetings                           8.0h    (none)
│  Deploy prep & deploy               4.5h    INFRAWEB
│  ... 25 more tasks ...
│  ─────────────────────────────────────────────────
│  Total: 200.0h   ← this is the invoice total
│
│  ⚠ Warning if any entry already on a sent invoice
│
▼
STEP 3 ── Craft Invoice Lines
│
│  Write client-facing descriptions (~15 lines)
│  Each line = description text + optional task references (for LLM)
│
│  [ + Add line ]
│  ┌──────────────────────────────────────────┐
│  │ Added Rewards Customer Dashboard    [✎] │  tasks: [AW-6637]
│  │ Refactored Design Request data model[✎] │  tasks: [AW-6522]
│  │ Hatch Product & LMS Integration    [✎] │  tasks: [AW-6761]
│  │ ...                                      │
│  └──────────────────────────────────────────┘
│  Drag to reorder. Add, edit, delete freely.
│
▼
STEP 4 ── Generate Descriptions (LLM) [optional]
│
│  [ Generate all descriptions ]
│      ↓ fires LlmClient with task context
│      ↓ populates blank descriptions
│      ↓ user reviews + edits each one
│
│  If LLM unavailable: error shown, lines stay blank,
│  wizard continues — user fills manually.
│
▼
STEP 5 ── Preview
│
│  ┌──────────────────────────────────────────────┐
│  │  INVOICE ARGEN-0316                          │
│  │  Jun 1 – Jun 30, 2026                        │
│  │                                              │
│  │  Added Rewards Customer Dashboard            │
│  │  Refactored Design Request data model        │
│  │  Hatch Product & LMS Integration             │
│  │  ...                                         │
│  │                                              │
│  │  Project Code  Description         Hours     │
│  │  ──────────────────────────────────────────  │
│  │  DSNSERV       Design Services     85.0      │
│  │  INFRAWEB      Rails Upgrades      72.0      │
│  │  (Meetings, misc: counted in total,          │
│  │   not shown in project chart)                │
│  │                                              │
│  │  Total Hours:  200.0                         │
│  │  Rate:         $X/hr                         │
│  │  Amount Due:   $Y                            │
│  └──────────────────────────────────────────────┘
│
▼
STEP 6 ── Finalize
│
│  [ Finalize Invoice ]
│      ↓ snapshot total_hours = 200.0
│      ↓ snapshot total_amount = 200.0 × rate
│      ↓ stamp all included TimeEntries with invoice_id
│      ↓ assign invoice_number "ARGEN-0316"
│      ↓ status → ready
│
▼
READY → [ Mark as Sent ] → SENT (sent_at stamped)
                               ↓
                         [ Mark as Paid ] → PAID (paid_at stamped)
```

---

## 3. Invoice Lifecycle

```
  draft ──────► ready ──────► sent ──────► paid
    │              │             │            │
  Editing        PDF can      sent_at      paid_at
  allowed        generate     stamped      stamped
                              TimeEntries
                              locked (soft)
```

**Soft lock:** editing or deleting a TimeEntry on a `sent` invoice shows a warning but is allowed. The invoice `total_hours` and `total_amount` are already snapshotted — the client's number never changes.

---

## 4. TimeEntry Lifecycle

```
  Created
  invoice_id: nil  ← un-billed, shows up in wizard
       │
       │ [included in invoice wizard step 2]
       │
       ▼
  Stamped
  invoice_id: 42   ← billed, soft-lock applies
       │
       │ [optional — soft-lock warning]
       ▼
  Edited / Deleted
  (invoice snapshot unchanged)
```

---

## 5. Task Lifecycle

```
  active  ←──────── default
    │
    │ [archive — when work is complete]
    ▼
  archived
    │  hidden from quick-entry autocomplete
    │  preserved in all historical records
    │  still shows in reports and task list (filtered)
    │
    │  [un-archive if needed]
    └────────────────────────────► active
```

---

## 6. Data Flow: From Log to Invoice

```
  Daily logs
  ──────────
  TimeEntry { task: AW-6522, date: Jun 4, hours: 5.0 }
  TimeEntry { task: Meetings, date: Jun 4, hours: 1.0 }
  TimeEntry { task: AW-6522, date: Jun 5, hours: 3.0 }
  ... (200h across 30 tasks over the month)

                    │
                    │ Invoice wizard (Jun 1–30)
                    ▼

  Invoice ARGEN-0316
  ──────────────────
  total_hours:  200.0           ← SUM of all billable TimeEntries
  total_amount: $Y              ← 200.0 × rate

  InvoiceLines (client narrative)
    "Refactored Design Request data model"   ← covers AW-6522 (8h)
    "Added Rewards Dashboard"                ← covers AW-6637 (3h)
    "Hatch Product Integration"              ← covers AW-6761 (7h)
    ... ~15 lines                            ← curated, no hours shown

  Project Summary (computed from stamped TimeEntries)
    DSNSERV  Design Services   85.0h
    INFRAWEB Rails Upgrades    72.0h
    (Meetings 43h: in total, not in chart)
```
