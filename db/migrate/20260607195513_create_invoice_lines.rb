class CreateInvoiceLines < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_lines do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :description, null: false
      t.integer :sort_order, null: false, default: 0
      t.json :task_ids

      t.timestamps
    end
  end
end
