class ReplaceTaskIdsWithTaskId < ActiveRecord::Migration[8.1]
  def change
    remove_column :invoice_lines, :task_ids, :json
    add_column :invoice_lines, :task_id, :integer
    add_index :invoice_lines, :task_id
    add_foreign_key :invoice_lines, :tasks, column: :task_id
  end
end
