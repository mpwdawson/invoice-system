# frozen_string_literal: true

class ContractorProfile < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true
end
