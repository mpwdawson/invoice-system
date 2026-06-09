# frozen_string_literal: true

require 'rails_helper'

describe ProjectCodes::ImportService do
  subject { described_class.call(customer:, csv_text:) }

  let(:customer) { create(:customer) }

  context 'with valid CSV containing new codes' do
    let(:csv_text) do
      <<~CSV
        Project Code,Description
        FRICTION,Commercial-Sales Territory Assignment
        AIFIRST,IS-AI Initiative
      CSV
    end

    it 'creates both project codes' do
      expect { subject }.to change(ProjectCode, :count).by(2)
    end

    it 'returns both codes in created' do
      expect(subject.created).to contain_exactly('FRICTION', 'AIFIRST')
    end

    it 'returns nothing in skipped or errors' do
      expect(subject.skipped).to be_empty
      expect(subject.errors).to be_empty
    end
  end

  context 'when a code already exists for the customer' do
    let!(:existing) { create(:project_code, customer:, code: 'FRICTION') }

    let(:csv_text) do
      <<~CSV
        Project Code,Description
        FRICTION,Commercial-Sales Territory Assignment
        AIFIRST,IS-AI Initiative
      CSV
    end

    it 'skips the existing code' do
      expect(subject.skipped).to eq(['FRICTION'])
    end

    it 'creates only the new code' do
      expect(subject.created).to eq(['AIFIRST'])
    end

    it 'does not duplicate the existing record' do
      expect { subject }.to change(ProjectCode, :count).by(1)
    end
  end

  context 'with mixed-case codes in the input' do
    let(:csv_text) do
      <<~CSV
        Project Code,Description
        friction,Commercial-Sales Territory Assignment
      CSV
    end

    it 'upcases the code before saving' do
      subject
      expect(ProjectCode.last.code).to eq('FRICTION')
    end

    it 'returns the upcased code in created' do
      expect(subject.created).to eq(['FRICTION'])
    end
  end

  context 'when an existing code matches case-insensitively' do
    let!(:existing) { create(:project_code, customer:, code: 'FRICTION') }

    let(:csv_text) do
      <<~CSV
        Project Code,Description
        friction,Commercial-Sales Territory Assignment
      CSV
    end

    it 'skips the row without creating a duplicate' do
      expect { subject }.not_to change(ProjectCode, :count)
      expect(subject.skipped).to eq(['FRICTION'])
    end
  end

  context 'with a row that has a blank code column' do
    let(:csv_text) do
      <<~CSV
        Project Code,Description
        ,Some description
        AIFIRST,IS-AI Initiative
      CSV
    end

    it 'skips the blank row' do
      expect(subject.created).to eq(['AIFIRST'])
      expect(subject.skipped).to be_empty
      expect(subject.errors).to be_empty
    end
  end

  context 'with a code that fails model validation (blank description)' do
    let(:csv_text) do
      <<~CSV
        Project Code,Description
        BROKEN,
      CSV
    end

    it 'does not create the record' do
      expect { subject }.not_to change(ProjectCode, :count)
    end

    it 'returns the code in errors' do
      expect(subject.errors.first).to include('BROKEN')
    end

    it 'returns nothing in created or skipped' do
      expect(subject.created).to be_empty
      expect(subject.skipped).to be_empty
    end
  end

  context 'with malformed CSV' do
    let(:csv_text) { "Project Code,Description\n\"unclosed quote,bad" }

    it 'returns an empty result without raising' do
      expect { subject }.not_to raise_error
      expect(subject.created).to be_empty
      expect(subject.skipped).to be_empty
      expect(subject.errors).to be_empty
    end
  end

  context 'with an empty string' do
    let(:csv_text) { '' }

    it 'returns an empty result' do
      expect(subject.created).to be_empty
      expect(subject.skipped).to be_empty
      expect(subject.errors).to be_empty
    end
  end
end
