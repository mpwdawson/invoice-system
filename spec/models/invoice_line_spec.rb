# frozen_string_literal: true

require 'rails_helper'

describe InvoiceLine do
  subject { build(:invoice_line) }

  describe 'associations' do
    it { is_expected.to belong_to(:invoice) }
    it { is_expected.to belong_to(:task).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:description) }
  end
end
