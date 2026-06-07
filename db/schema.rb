# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_07_030618) do
  create_table "contractor_profiles", force: :cascade do |t|
    t.text "address"
    t.text "bank_details"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "tax_number"
    t.datetime "updated_at", null: false
  end

  create_table "customer_rates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.date "effective_from", null: false
    t.decimal "rate", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_rates_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.text "address"
    t.string "contact_email"
    t.string "contact_name"
    t.datetime "created_at", null: false
    t.string "invoice_prefix"
    t.string "name", null: false
    t.boolean "requires_project_codes", default: false, null: false
    t.datetime "updated_at", null: false
  end

  create_table "project_codes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.string "description", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_project_codes_on_customer_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.boolean "billable", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.string "invoice_name"
    t.text "notes"
    t.integer "project_code_id"
    t.string "status", default: "active", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_tasks_on_customer_id"
    t.index ["project_code_id"], name: "index_tasks_on_project_code_id"
    t.index ["status"], name: "index_tasks_on_status"
  end

  create_table "ticket_references", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "number", null: false
    t.string "prefix", null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id", "prefix", "number"], name: "index_ticket_references_on_task_id_and_prefix_and_number", unique: true
    t.index ["task_id"], name: "index_ticket_references_on_task_id"
  end

  create_table "time_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.decimal "hours", precision: 4, scale: 1, null: false
    t.integer "invoice_id"
    t.text "notes"
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_time_entries_on_invoice_id"
    t.index ["task_id", "date"], name: "index_time_entries_on_task_id_and_date", unique: true
    t.index ["task_id"], name: "index_time_entries_on_task_id"
  end

  add_foreign_key "customer_rates", "customers"
  add_foreign_key "project_codes", "customers"
  add_foreign_key "tasks", "customers"
  add_foreign_key "tasks", "project_codes"
  add_foreign_key "ticket_references", "tasks"
  add_foreign_key "time_entries", "tasks"
end
