# frozen_string_literal: true

require 'rails_helper'

describe ProjectCode do
  subject { build(:project_code) }

  describe 'associations' do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to have_many(:tasks) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe 'defaults' do
    it 'is active by default' do
      project_code = build(:project_code)
      expect(project_code.active).to be(true)
    end
  end

  describe 'destroy restriction' do
    let(:customer)     { create(:customer) }
    let(:project_code) { create(:project_code, customer: customer) }

    it 'can be destroyed when no tasks are assigned' do
      project_code.destroy
      expect(project_code.destroyed?).to be(true)
    end

    it 'cannot be destroyed when tasks are assigned' do
      create(:task, customer: customer, project_code: project_code)
      project_code.destroy
      expect(project_code.destroyed?).to be(false)
      expect(project_code.errors).to be_present
    end
  end

  describe 'scopes' do
    let(:customer)       { create(:customer) }
    let!(:active_code)   { create(:project_code, customer: customer, active: true) }
    let!(:inactive_code) { create(:project_code, customer: customer, active: false) }

    describe '.active' do
      it 'includes active codes' do
        expect(described_class.active).to include(active_code)
      end

      it 'excludes inactive codes' do
        expect(described_class.active).not_to include(inactive_code)
      end
    end

    describe '.ordered' do
      it 'orders by code alphabetically' do
        create_list(:project_code, 3, customer: customer)
        expect(described_class.where(customer: customer).ordered.map(&:code)).to eq(
          described_class.where(customer: customer).map(&:code).sort
        )
      end
    end
  end
end
