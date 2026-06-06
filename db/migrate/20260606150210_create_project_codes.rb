class CreateProjectCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :project_codes do |t|
      t.references :customer, null: false, foreign_key: true, index: true
      t.string  :code,        null: false
      t.string  :description, null: false
      t.boolean :active,      null: false, default: true

      t.timestamps
    end
  end
end
