# frozen_string_literal: true

class InvoiceLine < ApplicationRecord
  belongs_to :invoice
  belongs_to :task, optional: true

  validates :description, presence: true
end
