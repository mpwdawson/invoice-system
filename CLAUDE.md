# Invoice System — Claude Code Instructions

## Key files to understand the codebase

- `README.md` - Tech stack, configuration, and local setup
- `Gemfile` - Dependencies
- `db/schema.rb` - Table structures and relationships
- `app/{models,services}/**/*.rb` - Business logic, associations, and service objects
- `config/routes.rb` - URL structure and available actions
- `app/javascript/controllers/**/*.js` - Existing Stimulus patterns
- `app/views/layouts/application.html.erb` - How Turbo/CSS are included
- `.rubocop.yml` - Preferred syntax (do not run linting)
- `wiki/` - Design decisions, data model, workflows, and epic stories

## Architecture

```
app/
  controllers/   # Thin. Authenticate session. Delegate to services.
  models/        # Persistence: validations, associations, scopes, simple predicates.
  views/         # ERB markup only. No logic.
  services/      # Business logic. Orchestrates models, APIs, side effects.
  javascript/    # Stimulus controllers only. No inline scripts.
```

## Core Directives

- **Skinny everything:** Controllers authenticate and orchestrate. Models persist. Services own business logic. Views display.
- **Services:** `.call` class method as primary entry point. Namespace by domain (e.g. `Invoices::FinalizeService`). Use `attr_reader` for constructor-injected dependencies; never use `@ivar` outside `initialize`.
- **Callbacks:** Only for data normalization (`before_validation`, `before_save`). Side effects (jobs, external APIs, LLM calls) belong in services — never in callbacks.
- **Frontend:** Stimulus controllers for all JS interactivity. No inline scripts.
- **Navigation:** Turbo Morphing for page transitions. Turbo Frames for isolated sections. Turbo Streams for partial DOM updates.
- **No premature abstraction:** Don't extract until complexity demands it. Three similar lines > wrong abstraction.
- **Explicit > implicit:** Clear service calls over hidden callbacks. Named methods over metaprogramming.

## Naming Conventions

| Layer      | Pattern                  | Example                         |
|------------|--------------------------|---------------------------------|
| Model      | Singular PascalCase      | `Invoice`, `TimeEntry`          |
| Controller | Plural PascalCase        | `TimeEntriesController`         |
| Service    | Namespaced + `Service`   | `Invoices::FinalizeService`     |
| Query      | Namespaced + `Query`     | `TimeEntries::UnbilledQuery`    |
| Job        | Descriptive + `Job`      | `GenerateInvoiceDescriptionJob` |
| Form       | Descriptive + `Form`     | `InvoiceWizardForm`             |

## Testing Conventions

- Mirror `app/` in `spec/` — files must end in `_spec.rb`.
- Use active verbs: `it "creates a time entry"` not `it "should create a time entry"`.
- Use FactoryBot. Prefer `build` / `build_stubbed` over `create` unless DB persistence is required.
- Use `let` / `let!` for all named test data. Never use instance variables (`@user`).
- Use `instance_double` instead of plain `double` to ensure mocked methods exist.
- Define the primary action under test as `subject { ... }` at the top of `describe`. Always call `subject` explicitly inside `it` blocks.
- Focus on business logic. Do not test standard Rails framework behaviour.

**What to test and when:**
- **Models:** test-after, immediately after each story. Validations, scopes, key methods.
- **Service objects:** spec the interface (inputs + expected outputs) *before* implementing — these hold the most complex logic.
- **Request specs:** auth flow and critical form submissions only. Not exhaustive.
- **System/Capybara specs:** skip in v1. Logic lives in models/services; browser tests are slow and brittle for a solo tool.
- Every story is not complete until its model + service specs are written and green.

## Key Commands

```bash
# Tests — run before marking any story done
bundle exec rspec                            # Full suite
bundle exec rspec spec/path/to_spec.rb       # Specific file
bundle exec rspec spec/path/to_spec.rb:25    # Specific line

# Security
bin/brakeman --no-pager                      # Static security analysis

# Database
bin/rails db:migrate
bin/rails db:migrate:status
bin/rails console
```
