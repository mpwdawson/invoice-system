# frozen_string_literal: true

require 'rails_helper'

describe TasksController do
  before { post login_path, params: { password: 'test_password' } }

  let(:customer) { create(:customer) }
  let(:task)     { create(:task, customer: customer) }

  describe 'GET #index' do
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

  describe 'GET #show' do
    subject { get task_path(task) }

    it 'renders the show page' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #new' do
    subject { get new_task_path }

    it 'renders the new form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
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

  describe 'GET #edit' do
    subject { get edit_task_path(task) }

    it 'renders the edit form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH #update' do
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

  describe 'GET #search' do
    subject { get search_tasks_path, params: params }

    let!(:customer_task)  { create(:task, customer: customer, title: 'Alpha Work Item') }
    let!(:other_customer) { create(:customer) }
    let!(:other_task)     { create(:task, customer: other_customer, title: 'Beta Work Item') }

    context 'without a customer_id' do
      let(:params) { { query: 'Work' } }

      it 'returns tasks from all customers' do
        subject
        expect(response.body).to include('Alpha Work Item')
        expect(response.body).to include('Beta Work Item')
      end
    end

    context 'with a customer_id' do
      let(:params) { { query: 'Work', customer_id: customer.id } }

      it 'returns only tasks for that customer' do
        subject
        expect(response.body).to include('Alpha Work Item')
        expect(response.body).not_to include('Beta Work Item')
      end
    end
  end

  describe 'GET #inline_new' do
    subject { get inline_new_tasks_path, params: params }

    context 'with a title param' do
      let(:params) { { title: 'New Feature Work' } }

      it 'returns 200' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'pre-fills the title in the response' do
        subject
        expect(response.body).to include('New Feature Work')
      end
    end

    context 'with a customer_id param' do
      let!(:params) { { title: 'New Feature Work', customer_id: customer.id } }

      it 'pre-selects the customer in the form' do
        subject
        expect(response.body).to include("selected=\"selected\" value=\"#{customer.id}\"")
      end
    end
  end

  describe 'POST #inline_create' do
    subject { post inline_create_tasks_path, params: params }

    context 'with valid params' do
      let(:params) { { task: { title: 'Design homepage', customer_id: customer.id } } }

      it 'creates a task' do
        expect { subject }.to change(Task, :count).by(1)
      end

      it 'returns 200 with auto-select content containing the task id' do
        subject
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(Task.last.id.to_s)
      end
    end

    context 'with invalid params (blank title)' do
      let(:params) { { task: { title: '', customer_id: customer.id } } }

      it 'does not create a task' do
        expect { subject }.not_to change(Task, :count)
      end

      it 'returns unprocessable_content' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH #update_inline' do
    subject { patch update_inline_task_path(task), params: params, as: :json }

    context 'with a valid title' do
      let(:params) { { task: { title: 'Renamed title' } } }

      it 'updates the task title and returns 200' do
        subject
        expect(response).to have_http_status(:ok)
        expect(task.reload.title).to eq('Renamed title')
      end
    end

    context 'with a blank title' do
      let(:params) { { task: { title: '' } } }

      it 'does not update the task and returns 422' do
        original_title = task.title
        subject
        expect(response).to have_http_status(:unprocessable_content)
        expect(task.reload.title).to eq(original_title)
      end
    end
  end

  describe 'DELETE #destroy' do
    subject { delete task_path(task) }

    context 'with no time entries' do
      before { task }

      it 'destroys the task and redirects to index' do
        expect { subject }.to change(Task, :count).by(-1)
        expect(response).to redirect_to(tasks_path)
      end
    end

    context 'with time entries' do
      let!(:entry) { create(:time_entry, task:) }

      it 'does not destroy the task and redirects to edit with alert' do
        expect { subject }.not_to change(Task, :count)
        expect(response).to redirect_to(edit_task_path(task))
      end
    end
  end

  describe 'PATCH #archive' do
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
