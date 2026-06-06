class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :customer,     null: false, foreign_key: true
      t.references :project_code, null: true,  foreign_key: true
      t.string  :title,        null: false
      t.string  :invoice_name
      t.text    :notes
      t.string  :status,       null: false, default: "active"
      t.boolean :billable,     null: false, default: true
      t.timestamps
    end

    add_index :tasks, :status
  end
end
