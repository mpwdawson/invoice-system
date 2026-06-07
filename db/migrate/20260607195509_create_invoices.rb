class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :customer, null: true, foreign_key: true
      t.integer :sequence_number, null: false
      t.date :period_start
      t.date :period_end
      t.string :status, null: false, default: 'draft'
      t.decimal :rate, precision: 10, scale: 2
      t.decimal :total_hours, precision: 6, scale: 1
      t.decimal :total_amount, precision: 10, scale: 2
      t.datetime :sent_at
      t.datetime :paid_at
      t.integer :wizard_current_step
      t.text :notes

      t.timestamps
    end

    add_index :invoices, :sequence_number, unique: true
    add_index :invoices, :status
  end
end
