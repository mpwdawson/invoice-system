# frozen_string_literal: true

require 'rails_helper'

describe TimeEntry do
  subject { build(:time_entry) }

  describe 'associations' do
    it { is_expected.to belong_to(:task) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:hours) }
    it { is_expected.to validate_numericality_of(:hours).is_greater_than(0) }

    it 'rejects hours that are not a multiple of 0.5' do
      entry = build(:time_entry, hours: 0.3)
      expect(entry).not_to be_valid
      expect(entry.errors[:hours]).to be_present
    end

    it 'accepts 0.5 hours' do
      expect(build(:time_entry, hours: 0.5)).to be_valid
    end

    it 'accepts 1.5 hours' do
      expect(build(:time_entry, hours: 1.5)).to be_valid
    end

    it 'rejects negative hours' do
      expect(build(:time_entry, hours: -1.0)).not_to be_valid
    end
  end

  describe 'uniqueness' do
    let(:task) { create(:task) }
    let!(:existing) { create(:time_entry, task: task, date: Date.current) }

    it 'rejects a second entry for the same task and date' do
      duplicate = build(:time_entry, task: task, date: Date.current)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:date]).to be_present
    end

    it 'allows a different date for the same task' do
      expect(build(:time_entry, task: task, date: Date.current - 1)).to be_valid
    end
  end

  describe '.log' do
    let(:task) { create(:task) }
    let(:date) { Date.current }

    context 'when no entry exists for the task and date' do
      subject { described_class.log(task: task, date: date, hours: 1.5) }

      it 'creates a new time entry' do
        expect { subject }.to change(described_class, :count).by(1)
      end

      it 'sets the correct hours' do
        expect(subject.hours).to eq(1.5)
      end

      it 'returns a TimeEntry' do
        expect(subject).to be_a(described_class)
      end
    end

    context 'when an entry already exists for the task and date' do
      subject { described_class.log(task: task, date: date, hours: 0.5) }

      let!(:existing) { create(:time_entry, task: task, date: date, hours: 1.0) }

      it 'does not create a second entry' do
        expect { subject }.not_to(change(described_class, :count))
      end

      it 'increments the hours on the existing entry' do
        expect(subject.hours).to eq(1.5)
      end

      it 'returns the existing entry' do
        expect(subject.id).to eq(existing.id)
      end
    end
  end
end
