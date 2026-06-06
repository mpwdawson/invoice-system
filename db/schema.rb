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

ActiveRecord::Schema[8.1].define(version: 2026_06_06_150210) do
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

  add_foreign_key "customer_rates", "customers"
  add_foreign_key "project_codes", "customers"
end
