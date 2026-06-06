class CreateContractorProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :contractor_profiles do |t|
      t.string :name
      t.text :address
      t.string :email
      t.string :tax_number
      t.text :bank_details

      t.timestamps
    end
  end
end
