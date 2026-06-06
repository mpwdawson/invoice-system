# Architecture

## Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| **Ruby** | 4.0.5 | |
| **Rails** | 8.1.3 | |
| **Database** | SQLite (3 files) | See below |
| **Background Jobs** | Solid Queue | Rails 8 built-in, SQLite-backed. Included but not wired to app features in v1 — ready for async LLM when needed |
| **ActionCable** | Not used (v1) | No real-time requirements; single user. Add if async LLM is introduced later |
| **CSS** | Tailwind CSS | Via `tailwindcss-rails` gem — no Node, no build step. Dark mode via `class` strategy — Stimulus controller toggles `dark` on `<html>`, persisted to `localStorage`. |
| **JavaScript** | Importmap | No bundler, no `node_modules`. Stimulus controllers only, no inline scripts |
| **Frontend JS** | Stimulus | For local UI behaviour: date picker, form resets, confirmation dialogs |
| **Navigation** | Turbo Morphing | Default for all page navigations — SPA feel, zero JS |
| **Isolation** | Turbo Frames | Independent sections: task autocomplete, preview panel, wizard steps, inline edits |
| **Partial updates** | Turbo Streams | Post-save DOM surgery: append entry to day log, update running totals, flash messages |
| **Testing** | RSpec | + factory_bot_rails, shoulda-matchers, capybara |

---

## SQLite — Three Database Files

Rails 8 supports multiple SQLite databases. Keep concerns isolated to avoid lock contention:

```yaml
# config/database.yml
production:
  primary:
    database: storage/production.sqlite3      # App data
  queue:
    database: storage/queue.sqlite3           # Solid Queue jobs
    migrations_paths: db/queue_migrate
  cache:
    database: storage/cache.sqlite3           # Solid Cache
    migrations_paths: db/cache_migrate
```

All three files live in `storage/` and should be excluded from `.gitignore` in development, backed up in production.

---

## Turbo Patterns by Screen

### Log Time Screen (combined quick entry + history)
The default screen after login. Entry form at top; scrollable date-grouped log below.
```
[Turbo Frame] task-preview
  — updates as user types/selects task
  — shows: task name, customer, project code
  — if same task+date exists: "Already logged 0.5hrs → adding 1.5 → total: 2.0hrs"

[Turbo Frame] task-create (inline, in search dropdown)
  — expands when no task matches search
  — saves new task without leaving the page, then auto-selects it

[Turbo Stream] after save
  — appends new/updated entry to the correct date group in the log below
  — updates the day's running total
  — form resets (date persists, task clears)

[Turbo Stream] inline edit
  — clicking ✎ on any log entry opens an inline edit form for hours/date
  — save updates the row in place without reload
```

### Invoice Wizard
Linear, one page per step. State persisted to the invoice record between steps.
```
[Turbo Morphing] — step-to-step navigation (each step is a full page)

[Turbo Stream] llm-name-generation (v1: fills all at once after sync call)
  — populates description fields in the lines table
```

### Reports
```
[Turbo Morphing] — standard navigation
[Turbo Frame] report-results
  — filter form submits reload only the results section
```

---

## LLM Integration

- **Service object:** `LlmClient` — configurable endpoint URL + model name via ENV
- **Pattern:** Extracted from OpenClaw codebase (to be done when building S-09)
- **ENV vars:**
  ```
  LLM_ENDPOINT=http://192.168.1.x:11434/v1
  LLM_MODEL=qwen2.5-coder:32b
  LLM_TIMEOUT=30
  ```
- **v1:** Synchronous call in the invoice wizard. 30s timeout. Graceful degradation — error per line, names stay blank for manual entry.
- **Future:** Background job via Solid Queue + Turbo Stream broadcast when hardware improves.

---

## Authentication

- Single-password session login
- Password set via `ENV["APP_PASSWORD"]`
- `SessionsController` with bcrypt or plain ENV comparison — no Devise
- Session cookie persists across page loads

---

## Testing Stack

```ruby
# Gemfile (test group)
gem "rspec-rails"
gem "factory_bot_rails"
gem "shoulda-matchers"
gem "capybara"           # system tests for Turbo/Stimulus flows
```

Test approach:
- **Models:** test-after, shipped with each story. Validations, scopes, key methods.
- **Service objects:** spec interface before implementing (inputs + expected outputs). Most complex logic lives here.
- **Request specs:** auth flow and critical form submissions only.
- **System/Capybara specs:** skipped in v1 — logic lives in models/services; browser tests are slow and brittle for a solo tool.
- LLM calls stubbed in all tests — no live calls.
- Run `bundle exec rspec` before marking any story done. Run `bin/brakeman --no-pager` separately for security checks.

---

## Deployment (v1)

```bash
rails server -b 192.168.1.x -p 3005
```

Running directly on a home network machine. No Docker in v1 — add once the app is stable and the first invoice is generated.

**Backups:** Cron job copies `storage/production.sqlite3` to Google Drive / Dropbox on a schedule.

---

## Out of Scope (v1)

- Docker / containerization
- Litestream / continuous replication
- ActionCable / WebSockets
- Async LLM (Solid Queue wired to app features)
- API endpoints
- Node.js / esbuild / Vite
