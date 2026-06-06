# frozen_string_literal: true

class CreateTicketReferences < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_references do |t|
      t.references :task, null: false, foreign_key: true
      t.string  :prefix, null: false
      t.integer :number, null: false
      t.timestamps
    end

    add_index :ticket_references, [:task_id, :prefix, :number], unique: true
  end
end
