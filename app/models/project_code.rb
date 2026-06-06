class ProjectCode < ApplicationRecord
  belongs_to :customer

  validates :code, :description, presence: true

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:code) }
end
