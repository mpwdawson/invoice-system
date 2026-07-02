class AddPrintViewFields < ActiveRecord::Migration[8.1]
  def change
    add_column :contractor_profiles, :phone, :string
    add_column :invoices, :po_number, :string
    add_column :customers, :currency, :string, default: "USD", null: false
  end
end
