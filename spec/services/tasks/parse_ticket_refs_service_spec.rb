# frozen_string_literal: true

require 'rails_helper'

describe Tasks::ParseTicketRefsService do
  subject { described_class.call(input: input) }

  context 'single ticket' do
    let(:input) { 'AW-6770' }

    it 'returns one ref' do
      expect(subject).to eq([{ prefix: 'AW', number: 6770 }])
    end
  end

  context 'multi-ticket with &' do
    let(:input) { 'AW-6770 & AW-6771 Some Title' }

    it 'returns both refs' do
      expect(subject).to contain_exactly(
        { prefix: 'AW', number: 6770 },
        { prefix: 'AW', number: 6771 }
      )
    end
  end

  context 'lowercase prefix' do
    let(:input) { 'aw-6770' }

    it 'upcases the prefix' do
      expect(subject).to eq([{ prefix: 'AW', number: 6770 }])
    end
  end

  context 'no ticket pattern' do
    let(:input) { 'some title with no refs' }

    it 'returns an empty array' do
      expect(subject).to eq([])
    end
  end

  context 'duplicate refs in input' do
    let(:input) { 'AW-6770 & AW-6770' }

    it 'deduplicates' do
      expect(subject).to eq([{ prefix: 'AW', number: 6770 }])
    end
  end

  context 'nil input' do
    let(:input) { nil }

    it 'returns an empty array' do
      expect(subject).to eq([])
    end
  end
end
