class AddExpenseFieldsToInvoiceLines < ActiveRecord::Migration[8.1]
  def change
    add_column :invoice_lines, :line_type, :string, default: "task", null: false
    add_column :invoice_lines, :quantity, :decimal, precision: 8, scale: 2
    add_column :invoice_lines, :unit_price, :decimal, precision: 10, scale: 2
  end
end
