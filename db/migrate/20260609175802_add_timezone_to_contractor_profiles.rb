class AddTimezoneToContractorProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :contractor_profiles, :timezone, :string, default: 'UTC', null: false
  end
end
