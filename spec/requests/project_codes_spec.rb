# frozen_string_literal: true

require 'rails_helper'

describe ProjectCodesController do
  before { post login_path, params: { password: 'test_password' } }

  let(:customer) { create(:customer) }

  describe 'GET #index' do
    subject { get customer_project_codes_path(customer) }

    it 'renders the index' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #new' do
    subject { get new_customer_project_code_path(customer) }

    it 'renders the new form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    subject { post customer_project_codes_path(customer), params: params }

    context 'with valid params' do
      let(:params) { { project_code: { code: 'DSNSERV', description: 'Design Services' } } }

      it 'creates a project code and redirects to the index' do
        expect { subject }.to change(ProjectCode, :count).by(1)
        expect(response).to redirect_to(customer_project_codes_path(customer))
      end
    end

    context 'with invalid params' do
      let(:params) { { project_code: { code: '', description: '' } } }

      it 're-renders the form with 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET #edit' do
    subject { get edit_customer_project_code_path(customer, project_code) }

    let(:project_code) { create(:project_code, customer: customer) }

    it 'renders the edit form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH #update' do
    subject { patch customer_project_code_path(customer, project_code), params: params }

    let(:project_code) { create(:project_code, customer: customer) }

    context 'with valid params' do
      let(:params) { { project_code: { code: 'UPDATED', description: 'Updated description' } } }

      it 'updates the project code and redirects to the index' do
        subject
        expect(response).to redirect_to(customer_project_codes_path(customer))
        expect(project_code.reload.code).to eq('UPDATED')
      end
    end

    context 'with invalid params' do
      let(:params) { { project_code: { code: '' } } }

      it 're-renders the form with 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:project_code) { create(:project_code, customer: customer) }

    context 'when no tasks are assigned' do
      it 'destroys the project code and redirects to index' do
        expect do
          delete customer_project_code_path(customer, project_code)
        end.to change(ProjectCode, :count).by(-1)
        expect(response).to redirect_to(customer_project_codes_path(customer))
      end
    end

    context 'when tasks are assigned' do
      before { create(:task, customer: customer, project_code: project_code) }

      it 'does not destroy the project code and redirects with alert' do
        expect do
          delete customer_project_code_path(customer, project_code)
        end.not_to change(ProjectCode, :count)
        expect(response).to redirect_to(customer_project_codes_path(customer))
      end
    end
  end

  describe 'GET #import_form' do
    subject { get import_form_customer_project_codes_path(customer) }

    it 'returns 200' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'renders the import turbo frame' do
      subject
      expect(response.body).to include('project-code-import')
    end
  end

  describe 'POST #import' do
    subject { post import_customer_project_codes_path(customer), params: params }

    context 'with valid CSV containing new codes' do
      let(:params) { { csv_text: "Project Code,Description\nFRICTION,Territory Assignment\nAIFIRST,AI Initiative" } }

      it 'creates the project codes' do
        expect { subject }.to change(ProjectCode, :count).by(2)
      end

      it 'redirects to the index with a created notice' do
        subject
        expect(response).to redirect_to(customer_project_codes_path(customer))
        expect(flash[:notice]).to include('created')
      end
    end

    context 'with a duplicate code' do
      let!(:existing) { create(:project_code, customer:, code: 'FRICTION') }
      let(:params)    { { csv_text: "Project Code,Description\nFRICTION,Territory Assignment" } }

      it 'redirects with a skipped notice' do
        subject
        expect(response).to redirect_to(customer_project_codes_path(customer))
        expect(flash[:notice]).to include('skipped')
      end
    end

    context 'with a code that fails model validation' do
      let(:params) { { csv_text: "Project Code,Description\nBROKEN," } }

      it 'returns 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'renders the import form with the error' do
        subject
        expect(response.body).to include('BROKEN')
      end
    end

    context 'with an empty CSV text' do
      let(:params) { { csv_text: '' } }

      it 'redirects with a nothing-to-import notice' do
        subject
        expect(response).to redirect_to(customer_project_codes_path(customer))
        expect(flash[:notice]).to eq('Nothing to import')
      end
    end
  end

  describe 'PATCH #archive' do
    let(:project_code) { create(:project_code, customer: customer, active: true) }

    it 'toggles active to false and redirects to the index' do
      patch archive_customer_project_code_path(customer, project_code)
      expect(project_code.reload.active).to be(false)
      expect(response).to redirect_to(customer_project_codes_path(customer))
    end

    it 'toggles active back to true when already archived' do
      project_code.update!(active: false)
      patch archive_customer_project_code_path(customer, project_code)
      expect(project_code.reload.active).to be(true)
    end
  end
end
