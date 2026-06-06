class Customer < ApplicationRecord
  has_many :customer_rates, dependent: :destroy
  has_many :project_codes,  dependent: :destroy

  validates :name, presence: true
end
