# frozen_string_literal: true

class Task < ApplicationRecord
  belongs_to :customer
  belongs_to :project_code, optional: true

  enum :status, { active: 'active', archived: 'archived' }, default: 'active'

  validates :title, presence: true

  validate :project_code_belongs_to_customer, if: -> { project_code_id.present? }

  scope :billable, -> { where(billable: true) }
  scope :ordered,  -> { order(:title) }

  private

  def project_code_belongs_to_customer
    return if project_code&.customer_id == customer_id

    errors.add(:project_code, 'must belong to the selected customer')
  end
end
