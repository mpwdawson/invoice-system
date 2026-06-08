# frozen_string_literal: true

require 'rails_helper'

describe ImportsController do
  before { post login_path, params: { password: 'test_password' } }

  let(:customer) { create(:customer) }

  # A pasted header row, a day with no hours/notes, and a ticket ref repeated
  # across two days — exercises header-skip, blank-row, and new-task-dedup
  # together against a single paste.
  let(:text) do
    <<~TEXT
      Date\tTime\tNotes
      5/1/2026\t6\tSprint Planning (1), PRJ-1234 Build Settings Page (4), Code Review (1)
      5/2/2026\t3\tPRJ-1234 Build Settings Page (3)
      5/10/2026\t\t
      5/11/2026\t5\tInternal Tooling Update (2), Client Sync Call (1), PRJ-5678 Refactor Auth Flow (2)
    TEXT
  end

  describe 'GET #new' do
    subject { get new_import_path }

    it 'renders the paste form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #preview' do
    subject { post preview_import_path, params: { customer_id: customer.id, text: } }

    it 'renders the preview, ignoring the header row and the empty day' do
      subject
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Sprint Planning')
      expect(response.body).to include('Code Review')
      expect(response.body).to include('Refactor Auth Flow')
    end
  end

  describe 'POST #create' do
    subject { post import_path, params: { customer_id: customer.id, text: } }

    it 'dedupes the repeated ticket ref into one task and skips the header/empty-day rows' do
      expect { subject }.to change(Task, :count).by(6).and change(TimeEntry, :count).by(7)
    end

    it 'renders the import report' do
      subject
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('7')
      expect(response.body).to include('time entries created')
      expect(response.body).to include('6')
      expect(response.body).to include('tasks created')
    end
  end
end
