# frozen_string_literal: true

require 'rails_helper'

describe 'TimeEntries' do
  before { post login_path, params: { password: 'test_password' } }

  let(:customer) { create(:customer) }
  let(:task)     { create(:task, customer: customer) }

  describe 'GET /log' do
    subject { get log_time_path }

    it 'renders the log time screen' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /time_entries/preview' do
    subject { get preview_time_entries_path, params: params }

    context 'without a task_id' do
      let(:params) { {} }

      it 'returns 200' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when no entry exists for the task and date' do
      let(:params) { { task_id: task.id, date: Date.current.to_s, hours: '1.5' } }

      it 'returns 200' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'shows the hours being added as the total' do
        subject
        expect(response.body).to include('1.5')
      end
    end

    context 'when an entry already exists for the task and date' do
      before { create(:time_entry, task: task, date: Date.current, hours: 1.0) }

      let(:params) { { task_id: task.id, date: Date.current.to_s, hours: '1.5' } }

      it 'returns 200' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'shows the already-logged message' do
        subject
        expect(response.body).to include('Already')
      end
    end
  end

  describe 'POST /time_entries' do
    subject { post time_entries_path, params: params, headers: { 'Accept' => 'text/vnd.turbo-stream.html' } }

    context 'with valid params for a new task and date' do
      let(:params) { { time_entry: { task_id: task.id, date: Date.current.to_s, hours: '1.5' } } }

      it 'creates a time entry' do
        expect { subject }.to change(TimeEntry, :count).by(1)
      end

      it 'returns a turbo stream response' do
        subject
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'when an entry already exists for the task and date' do
      let!(:existing) { create(:time_entry, task: task, date: Date.current, hours: 1.0) }
      let(:params)    { { time_entry: { task_id: task.id, date: Date.current.to_s, hours: '0.5' } } }

      it 'does not create a second entry' do
        expect { subject }.not_to change(TimeEntry, :count)
      end

      it 'increments hours on the existing entry' do
        subject
        expect(existing.reload.hours).to eq(1.5)
      end

      it 'returns a turbo stream response' do
        subject
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'with invalid params (zero hours)' do
      let(:params) { { time_entry: { task_id: task.id, date: Date.current.to_s, hours: '0' } } }

      it 'returns unprocessable_content' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
