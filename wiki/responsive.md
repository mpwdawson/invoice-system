# Responsive / Mobile Plan

## Context

The app currently has a fixed 224px sidebar that occupies the full left side of the screen — unusable on small displays. No responsive breakpoints exist on any page. The viewport meta tag is already present.

This plan covers the four areas worth tackling, in priority order. Reports, Customers, and Invoices are out of scope for now.

---

## Story Map

```
M-01  Collapsible sidebar         ✓ Done
  └─  M-02  Log Time responsive   ✓ Done
  └─  M-03  Project Codes shortcut (new nav link + flat overview page)  ✓ Done
  └─  M-04  Tasks index responsive  ✓ Done
```

M-03 is a new feature (nav shortcut + new page), not a reskin — independent of M-02 and M-04.

---

## M-01: Collapsible Sidebar

**Goal:** Sidebar hides off-screen on small displays; a hamburger opens it as a slide-over. Desktop behaviour unchanged.

**Pattern:**
- `md:` and up — sidebar is always visible, static layout (current behaviour preserved)
- Below `md:` — sidebar is `fixed inset-y-0 left-0 z-40 w-56`, off-screen by default (`-translate-x-full`), slides in on open (`translate-x-0`) with a CSS transition
- Backdrop — `fixed inset-0 z-30 bg-black/50` rendered behind the open sidebar; tap/click dismisses it
- Hamburger button — top-left of the main content area, only visible below `md:` (`md:hidden`)

**Files:**
- `app/views/layouts/application.html.erb` — responsive classes on `<aside>`, hamburger button, backdrop element
- `app/javascript/controllers/sidebar_controller.js` — `toggle`, `open`, `close` actions; sidebar already has `data-turbo-permanent` so dark mode state survives

**Complexity:** Small

---

## M-02: Log Time Responsive

**Goal:** `/` page works comfortably on a phone. This is the primary daily-use screen.

**What needs work:**

| Element | Problem | Fix |
|---------|---------|-----|
| Customer filter tabs | Could overflow horizontally | `overflow-x-auto whitespace-nowrap` on the tab row |
| Entry form inputs | Date/hours fixed-width on small screens | Full-width below `sm:` breakpoint |
| Entry row (`_entry_row`) | Too many columns for narrow screens — project code badge + billed/unbilled badge are clutter on mobile | Hide both badges below `sm:`; keep task name, hours, date, × |
| Log date headers | Fine as-is | No change needed |

**Files:**
- `app/views/time_entries/log.html.erb`
- `app/views/time_entries/_form.html.erb`
- `app/views/time_entries/_entry_row.html.erb`

**Complexity:** Small–Medium

---

## M-03: Project Codes Sidebar Shortcut

**Goal:** A "Project Codes" link in the sidebar lands on a flat page showing all project codes grouped by customer — add, edit, and archive without going through Customer first.

**Current workflow (pain):** Sidebar → Customers → Customer show → Manage → filter/find → Edit

**Target workflow:** Sidebar → Project Codes → find the customer group → act

**Design:**
- New top-level route: `GET /project_codes` → `ProjectCodesOverviewController#index`
- Page lists all customers that have project codes (or could have them), each as a collapsible or always-open group
- Each group shows active codes with Edit / Archive buttons (linking to existing nested routes: `edit_customer_project_code_path` etc.)
- Each group has an inline "+ Add" link that goes to `new_customer_project_code_path`
- Archived codes shown in a collapsed/muted section per group

**Files:**
- `config/routes.rb` — add `get 'project_codes', to: 'project_codes_overview#index', as: :project_codes_overview`
- `app/controllers/project_codes_overview_controller.rb` — loads all customers with their project codes (`Customer.includes(:project_codes).order(:name)`)
- `app/views/project_codes_overview/index.html.erb`
- `app/views/layouts/application.html.erb` — add "Project Codes" nav link

**Note:** No new CRUD logic — all add/edit/archive forms remain on the existing nested `customers/:id/project_codes` routes. The overview page is a navigation layer only.

**Complexity:** Medium

---

## M-04: Tasks Index Responsive

**Goal:** `/tasks` is usable on a phone. Lower priority — glanceable is good enough; deep filtering is a desktop task.

**What needs work:**
- 6-column table overflows on small screens
- Filter bar with 6 inputs wraps awkwardly

**Fix:**
- Hide secondary columns below `sm:` — keep Title + Actions, hide Customer, Project Code, Billable, Created using `hidden sm:table-cell` / `hidden sm:table-header-cell`
- Filter bar already uses `flex-wrap` — inputs stack naturally; verify on narrow screens

**Files:**
- `app/views/tasks/index.html.erb`

**Complexity:** Small

---

## Build Order

| # | Story | Why first |
|---|-------|-----------|
| M-01 | Collapsible sidebar | Without this, all other mobile improvements land behind an unusable nav |
| M-02 | Log Time responsive | Highest daily-use priority |
| M-03 | Project Codes shortcut | Independent feature; can be done any time after M-01 |
| M-04 | Tasks index | Nice to have; least urgent |

## Out of Scope

- Reports (rarely used)
- Customers list (rarely used)
- Invoices (not complete yet)
- Settings
