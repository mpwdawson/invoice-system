# frozen_string_literal: true

require 'rails_helper'

describe Import::ParseLogService do
  subject { described_class.call(text:) }

  let(:date_str)         { '6/1/2026' }
  let(:stated_hours_str) { '11' }
  let(:notes)            { '' }
  let(:text)             { "#{date_str}\t#{stated_hours_str}\t#{notes}" }

  context 'with a single item carrying a ticket ref and hours' do
    let(:notes) { 'AW-6522 DesignRequest Polymorphic Refactor (5)' }

    it 'extracts the title without the ticket prefix' do
      expect(subject.first.items.first.title).to eq('DesignRequest Polymorphic Refactor')
    end

    it 'extracts the ticket ref' do
      expect(subject.first.items.first.ticket_refs).to eq([{ prefix: 'AW', number: 6522 }])
    end

    it 'extracts the hours' do
      expect(subject.first.items.first.hours).to eq(5.0)
    end
  end

  context 'with multiple comma-separated items on one row' do
    let(:notes) { 'AI Meetings w/PK and Argen Bridge testing (2), QA Support (0.5), AW-6637 Rewards Dashboard Updates (1)' }

    it 'produces one entry per item' do
      expect(subject.first.items.map(&:title)).to eq(
        [
          'AI Meetings w/PK and Argen Bridge testing',
          'QA Support',
          'Rewards Dashboard Updates'
        ]
      )
    end
  end

  context 'with a multi-ticket & join' do
    let(:notes) { 'AW-6770 & AW-6771 Disable & Remove Autodesign (1.5)' }

    it 'extracts both refs' do
      expect(subject.first.items.first.ticket_refs).to contain_exactly(
        { prefix: 'AW', number: 6770 },
        { prefix: 'AW', number: 6771 }
      )
    end

    it 'strips both leading refs from the title but keeps the mid-title &' do
      expect(subject.first.items.first.title).to eq('Disable & Remove Autodesign')
    end
  end

  context 'with an incidental & that is not a ticket join' do
    let(:notes) { 'AI & Meetings (4), deploy prep & deploy (1)' }

    it 'produces no ticket refs' do
      expect(subject.first.items.map(&:ticket_refs)).to all(eq([]))
    end

    it 'keeps the & in the title untouched' do
      expect(subject.first.items.map(&:title)).to eq(['AI & Meetings', 'deploy prep & deploy'])
    end
  end

  context 'with a half-hour value' do
    let(:notes) { 'QA Support (0.5)' }

    it 'parses fractional hours' do
      expect(subject.first.items.first.hours).to eq(0.5)
    end
  end

  context 'with no hours marker present' do
    let(:notes) { 'Some open-ended task with no hours marker' }

    it 'returns nil hours' do
      expect(subject.first.items.first.hours).to be_nil
    end

    it 'uses the full text as the title' do
      expect(subject.first.items.first.title).to eq('Some open-ended task with no hours marker')
    end
  end

  context 'with no ticket prefix' do
    let(:notes) { 'Meetings (1), QA Support (0.5)' }

    it 'produces no ticket refs' do
      expect(subject.first.items.map(&:ticket_refs)).to all(eq([]))
    end

    it 'leaves the title untouched' do
      expect(subject.first.items.map(&:title)).to eq(['Meetings', 'QA Support'])
    end
  end

  context 'with a wildcard ref' do
    let(:notes) { 'AW-* Migrate Accounts Payable Page from React to Rails (2)' }

    it 'produces no ticket ref' do
      expect(subject.first.items.first.ticket_refs).to eq([])
    end

    it 'strips the wildcard prefix from the title' do
      expect(subject.first.items.first.title).to eq('Migrate Accounts Payable Page from React to Rails')
    end
  end

  context 'with a trailing blank comma segment' do
    let(:notes) { 'AW-6810 SF Disable Line Item Alert (0.5), ' }

    it 'produces no entry for the blank segment' do
      expect(subject.first.items.size).to eq(1)
    end
  end

  context 'with a header row' do
    let(:text) { "Date\tTime\tNotes" }

    it 'produces no day log' do
      expect(subject).to be_empty
    end
  end

  context 'with multiple day rows' do
    let(:text) do
      [
        "6/1/2026\t11\tQA Support (0.5)",
        "6/2/2026\t10\tDeploy prep (1)"
      ].join("\n")
    end

    it 'produces one day log per row' do
      expect(subject.size).to eq(2)
    end

    it 'parses each row date from the Date column' do
      expect(subject.map(&:date)).to eq([Date.new(2026, 6, 1), Date.new(2026, 6, 2)])
    end

    it 'captures stated hours from the Time column' do
      expect(subject.map(&:stated_hours)).to eq([11.0, 10.0])
    end
  end
end
