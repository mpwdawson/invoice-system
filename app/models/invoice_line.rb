# frozen_string_literal: true

class InvoiceLine < ApplicationRecord
  belongs_to :invoice

  validates :description, presence: true
end
