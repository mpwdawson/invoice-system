class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string  :name,                   null: false
      t.text    :address
      t.string  :contact_name
      t.string  :contact_email
      t.string  :invoice_prefix
      t.boolean :requires_project_codes, null: false, default: false

      t.timestamps
    end
  end
end
