class CreateTimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :time_entries do |t|
      t.references :task,    null: false, foreign_key: true
      t.references :invoice, null: true,  foreign_key: false
      t.date    :date,  null: false
      t.decimal :hours, null: false, precision: 4, scale: 1
      t.text    :notes

      t.timestamps
    end

    add_index :time_entries, [:task_id, :date], unique: true
  end
end
