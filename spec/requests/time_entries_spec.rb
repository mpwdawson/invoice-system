# frozen_string_literal: true

require 'rails_helper'

describe TimeEntriesController do
  before { post login_path, params: { password: 'test_password' } }

  let(:customer) { create(:customer) }
  let(:task)     { create(:task, customer: customer) }

  describe 'GET #log' do
    subject { get log_time_path }

    it 'renders the log time screen' do
      subject
      expect(response).to have_http_status(:ok)
    end

    context 'with a customer_id param' do
      let!(:other_customer) { create(:customer) }
      let!(:other_task)     { create(:task, customer: other_customer) }
      let!(:customer_entry) { create(:time_entry, task:, date: Date.current, hours: 1) }
      let!(:other_entry)    { create(:time_entry, task: other_task, date: Date.current, hours: 2) }

      it 'saves customer_id to the session' do
        get log_time_path, params: { customer_id: customer.id.to_s }
        expect(session[:log_customer_id]).to eq(customer.id.to_s)
      end

      it 'shows only that customer\'s entries in the log' do
        get log_time_path, params: { customer_id: customer.id }
        expect(response.body).to include(task.title)
        expect(response.body).not_to include(other_task.title)
      end
    end

    context 'with customer_id blank (All)' do
      it 'clears the session filter' do
        get log_time_path, params: { customer_id: customer.id.to_s }
        get log_time_path, params: { customer_id: '' }
        expect(session[:log_customer_id]).to be_nil
      end
    end

    context 'with no customer_id param but session filter set' do
      let!(:other_customer) { create(:customer) }
      let!(:other_task)     { create(:task, customer: other_customer) }
      let!(:other_entry)    { create(:time_entry, task: other_task, date: Date.current, hours: 2) }

      it 'uses the session filter' do
        get log_time_path, params: { customer_id: customer.id } # saves to session
        get log_time_path # no param — reads session
        expect(response.body).not_to include(other_task.title)
      end
    end
  end

  describe 'GET #preview' do
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

  describe 'POST #create' do
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

  describe 'GET #edit' do
    subject { get edit_time_entry_path(entry) }

    context 'for an unbilled entry' do
      let(:entry) { create(:time_entry, task:) }

      it 'returns ok' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'for a billed entry' do
      let(:entry) { create(:time_entry, task:, invoice_id: 99) }

      it 'includes a billed warning' do
        subject
        expect(response.body).to include('invoice')
      end
    end
  end

  describe 'PATCH #update' do
    subject { patch time_entry_path(entry), params: params, headers: { 'Accept' => 'text/vnd.turbo-stream.html' } }

    let(:entry) { create(:time_entry, task:, hours: 1.0) }

    context 'with valid hours' do
      let(:params) { { time_entry: { hours: '2.5', date: entry.date.to_s } } }

      it 'updates the entry' do
        subject
        expect(entry.reload.hours).to eq(2.5)
      end

      it 'returns a turbo stream' do
        subject
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'with invalid hours (zero)' do
      let(:params) { { time_entry: { hours: '0', date: entry.date.to_s } } }

      it 'returns unprocessable_content' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH #update_inline' do
    subject { patch update_inline_time_entry_path(entry), params: params, as: :json }

    let(:entry) { create(:time_entry, task:, hours: 1.0, date: Date.current) }

    context 'with valid params' do
      let(:params) { { time_entry: { hours: '3.0', date: Date.current.to_s } } }

      it 'updates the entry and returns 200' do
        subject
        expect(response).to have_http_status(:ok)
        expect(entry.reload.hours).to eq(3.0)
      end
    end

    context 'with invalid hours (zero)' do
      let(:params) { { time_entry: { hours: '0', date: Date.current.to_s } } }

      it 'does not update and returns 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
        expect(entry.reload.hours).to eq(1.0)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'for an unbilled entry' do
      subject { delete time_entry_path(entry), headers: { 'Accept' => 'text/vnd.turbo-stream.html' } }

      let!(:entry) { create(:time_entry, task:) }

      it 'deletes the entry' do
        expect { subject }.to change(TimeEntry, :count).by(-1)
      end

      it 'returns a turbo stream' do
        subject
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'for a billed entry' do
      subject { delete time_entry_path(entry), headers: { 'Accept' => 'text/vnd.turbo-stream.html' } }

      let!(:entry) { create(:time_entry, task:, invoice_id: 99) }

      it 'does not delete the entry' do
        expect { subject }.not_to change(TimeEntry, :count)
      end

      it 'returns the soft-lock warning' do
        subject
        expect(response.body).to include('invoice')
      end
    end

    context 'for a billed entry with force param' do
      subject { delete time_entry_path(entry), params: { force: true }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' } }

      let!(:entry) { create(:time_entry, task:, invoice_id: 99) }

      it 'deletes the entry' do
        expect { subject }.to change(TimeEntry, :count).by(-1)
      end
    end
  end
end
