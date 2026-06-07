# frozen_string_literal: true

require 'rails_helper'

describe 'Tasks' do
  before { post login_path, params: { password: 'test_password' } }

  let(:customer) { create(:customer) }
  let(:task)     { create(:task, customer: customer) }

  describe 'GET /tasks' do
    subject { get tasks_path }

    it 'renders the index' do
      subject
      expect(response).to have_http_status(:ok)
    end

    context 'with a title query' do
      it 'returns 200' do
        get tasks_path, params: { query: task.title }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with a ticket ref query' do
      before { create(:ticket_reference, task: task, prefix: 'AW', number: 6770) }

      it 'returns 200' do
        get tasks_path, params: { query: 'AW-6770' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with a query matching nothing' do
      it 'returns 200' do
        get tasks_path, params: { query: 'zzz_no_match' }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /tasks/:id' do
    subject { get task_path(task) }

    it 'renders the show page' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /tasks/new' do
    subject { get new_task_path }

    it 'renders the new form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /tasks' do
    subject { post tasks_path, params: params }

    context 'with valid params' do
      let(:params) { { task: { customer_id: customer.id, title: 'Design homepage' } } }

      it 'creates a task and redirects to show' do
        expect { subject }.to change(Task, :count).by(1)
        expect(response).to redirect_to(task_path(Task.last))
      end
    end

    context 'with invalid params' do
      let(:params) { { task: { customer_id: customer.id, title: '' } } }

      it 're-renders the form with 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /tasks/:id/edit' do
    subject { get edit_task_path(task) }

    it 'renders the edit form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /tasks/:id' do
    subject { patch task_path(task), params: params }

    context 'with valid params' do
      let(:params) { { task: { title: 'Updated title' } } }

      it 'updates the task and redirects to show' do
        subject
        expect(response).to redirect_to(task_path(task))
        expect(task.reload.title).to eq('Updated title')
      end
    end

    context 'with invalid params' do
      let(:params) { { task: { title: '' } } }

      it 're-renders the form with 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH /tasks/:id/archive' do
    it 'archives an active task and redirects to index' do
      patch archive_task_path(task)
      expect(task.reload.status).to eq('archived')
      expect(response).to redirect_to(tasks_path)
    end

    it 'restores an archived task' do
      task.update!(status: 'archived')
      patch archive_task_path(task)
      expect(task.reload.status).to eq('active')
    end
  end
end
