# frozen_string_literal: true

require 'rails_helper'

describe Tasks::ExtractTicketFromTitle do
  subject { described_class.call(title:) }

  context 'with AW prefix' do
    let(:title) { "AW-6833 Add Invoice Line Feature" }

    it 'extracts the ticket ref and strips it from the title' do
      expect(subject.title).to eq("Add Invoice Line Feature")
      expect(subject.ticket_ref).to eq("AW-6833")
    end
  end

  context 'with IA prefix' do
    let(:title) { "IA-9876 Fix login redirect" }

    it 'extracts the ticket ref' do
      expect(subject.title).to eq("Fix login redirect")
      expect(subject.ticket_ref).to eq("IA-9876")
    end
  end

  context 'with QAD prefix' do
    let(:title) { "QAD-4567 Update billing page" }

    it 'extracts the ticket ref' do
      expect(subject.title).to eq("Update billing page")
      expect(subject.ticket_ref).to eq("QAD-4567")
    end
  end

  context 'case insensitive — lowercase' do
    let(:title) { "aw-1234 Lowercase prefix" }

    it 'extracts and upcases the ticket ref' do
      expect(subject.title).to eq("Lowercase prefix")
      expect(subject.ticket_ref).to eq("AW-1234")
    end
  end

  context 'case insensitive — mixed case' do
    let(:title) { "Qad-999 Mixed case" }

    it 'extracts and upcases the ticket ref' do
      expect(subject.title).to eq("Mixed case")
      expect(subject.ticket_ref).to eq("QAD-999")
    end
  end

  context 'case insensitive — alternating case' do
    let(:title) { "iA-5555 Alternating" }

    it 'extracts and upcases the ticket ref' do
      expect(subject.title).to eq("Alternating")
      expect(subject.ticket_ref).to eq("IA-5555")
    end
  end

  context 'with no ticket prefix' do
    let(:title) { "Just a regular task title" }

    it 'returns the original title and nil ticket_ref' do
      expect(subject.title).to eq("Just a regular task title")
      expect(subject.ticket_ref).to be_nil
    end
  end

  context 'with leading and trailing whitespace' do
    let(:title) { "  AW-100 Padded title  " }

    it 'strips whitespace from both the title and extraction' do
      expect(subject.title).to eq("Padded title")
      expect(subject.ticket_ref).to eq("AW-100")
    end
  end

  context 'with an unrecognized prefix' do
    let(:title) { "JIRA-1234 Some task" }

    it 'does not extract' do
      expect(subject.title).to eq("JIRA-1234 Some task")
      expect(subject.ticket_ref).to be_nil
    end
  end

  context 'with ticket ref mid-title' do
    let(:title) { "Fix bug for AW-1234" }

    it 'does not extract — only leading refs are detected' do
      expect(subject.title).to eq("Fix bug for AW-1234")
      expect(subject.ticket_ref).to be_nil
    end
  end

  context 'with ticket ref only and no title' do
    let(:title) { "AW-6833" }

    it 'extracts the ticket ref and returns empty title' do
      expect(subject.title).to eq("")
      expect(subject.ticket_ref).to eq("AW-6833")
    end
  end

  context 'with empty string' do
    let(:title) { "" }

    it 'returns empty title and nil ticket_ref' do
      expect(subject.title).to eq("")
      expect(subject.ticket_ref).to be_nil
    end
  end

  context 'with nil' do
    let(:title) { nil }

    it 'returns empty title and nil ticket_ref' do
      expect(subject.title).to eq("")
      expect(subject.ticket_ref).to be_nil
    end
  end
end
