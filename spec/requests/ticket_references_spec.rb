# frozen_string_literal: true

require 'rails_helper'

describe TicketReferencesController do
  before { post login_path, params: { password: 'test_password' } }

  let(:task) { create(:task) }

  describe 'POST #create' do
    subject { post task_ticket_references_path(task), params: params, headers: { 'Accept' => 'text/vnd.turbo-stream.html' } }

    context 'with a valid ticket input' do
      let(:params) { { input: 'AW-6770' } }

      it 'creates a ticket reference' do
        expect { subject }.to change(TicketReference, :count).by(1)
      end

      it 'returns a turbo stream response' do
        subject
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'with multiple tickets' do
      let(:params) { { input: 'AW-6770 & AW-6771' } }

      it 'creates both refs' do
        expect { subject }.to change(TicketReference, :count).by(2)
      end
    end

    context 'with duplicate input' do
      let(:params) { { input: 'AW-6770' } }

      before { create(:ticket_reference, task: task, prefix: 'AW', number: 6770) }

      it 'is idempotent' do
        expect { subject }.not_to change(TicketReference, :count)
      end
    end

    context 'with no ticket pattern' do
      let(:params) { { input: 'some title text' } }

      it 'creates no refs' do
        expect { subject }.not_to change(TicketReference, :count)
      end
    end
  end

  describe 'DELETE #destroy' do
    subject { delete task_ticket_reference_path(task, ref), headers: { 'Accept' => 'text/vnd.turbo-stream.html' } }

    let(:ref) { create(:ticket_reference, task: task) }

    it 'destroys the ref' do
      ref
      expect { subject }.to change(TicketReference, :count).by(-1)
    end

    it 'returns a turbo stream response' do
      ref
      subject
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end
  end
end
