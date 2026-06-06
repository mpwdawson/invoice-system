class ProjectCode < ApplicationRecord
  belongs_to :customer
  has_many :tasks, dependent: :restrict_with_error

  validates :code, :description, presence: true

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:code) }
end
