# frozen_string_literal: true

require 'rails_helper'

describe Task do
  subject { build(:task) }

  describe 'associations' do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:project_code).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'defaults' do
    it 'defaults status to active' do
      expect(described_class.new.status).to eq('active')
    end

    it 'defaults billable to true' do
      expect(described_class.new.billable).to be(true)
    end
  end

  describe 'enum' do
    it { is_expected.to define_enum_for(:status).with_values(active: 'active', archived: 'archived').backed_by_column_of_type(:string) }

    it 'provides active? predicate' do
      expect(build(:task, status: 'active').active?).to be(true)
    end

    it 'provides archived? predicate' do
      expect(build(:task, status: 'archived').archived?).to be(true)
    end
  end

  describe 'scopes' do
    let(:customer) { create(:customer) }
    let!(:active_task)   { create(:task, customer: customer, status: 'active') }
    let!(:archived_task) { create(:task, customer: customer, status: 'archived') }
    let!(:unbillable)    { create(:task, customer: customer, billable: false) }

    describe '.active' do
      it 'includes active tasks' do
        expect(described_class.active).to include(active_task)
      end

      it 'excludes archived tasks' do
        expect(described_class.active).not_to include(archived_task)
      end
    end

    describe '.archived' do
      it 'includes archived tasks' do
        expect(described_class.archived).to include(archived_task)
      end

      it 'excludes active tasks' do
        expect(described_class.archived).not_to include(active_task)
      end
    end

    describe '.billable' do
      it 'includes billable tasks' do
        expect(described_class.billable).to include(active_task)
      end

      it 'excludes non-billable tasks' do
        expect(described_class.billable).not_to include(unbillable)
      end
    end
  end

  describe 'project_code customer validation' do
    let(:customer)       { create(:customer) }
    let(:other_customer) { create(:customer) }
    let(:project_code)   { create(:project_code, customer: customer) }

    it 'is valid when project_code belongs to the same customer' do
      task = build(:task, customer: customer, project_code: project_code)
      expect(task).to be_valid
    end

    it 'is invalid when project_code belongs to a different customer' do
      task = build(:task, customer: other_customer, project_code: project_code)
      expect(task).not_to be_valid
      expect(task.errors[:project_code]).to be_present
    end

    it 'is valid with no project_code' do
      task = build(:task, customer: customer, project_code: nil)
      expect(task).to be_valid
    end
  end
end
