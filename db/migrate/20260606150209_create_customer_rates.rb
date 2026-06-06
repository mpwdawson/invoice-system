class CreateCustomerRates < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_rates do |t|
      t.references :customer, null: false, foreign_key: true, index: true
      t.decimal :rate,           precision: 10, scale: 2, null: false
      t.date    :effective_from, null: false

      t.timestamps
    end
  end
end
