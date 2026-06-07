# frozen_string_literal: true

require 'rails_helper'

describe CustomersController do
  before { post login_path, params: { password: 'test_password' } }

  describe 'GET #index' do
    subject { get customers_path }

    it 'renders the index' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #new' do
    subject { get new_customer_path }

    it 'renders the new form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    subject { post customers_path, params: params }

    context 'with valid params' do
      let(:params) { { customer: { name: 'Argen', invoice_prefix: 'ARGEN' } } }

      it 'creates the customer and redirects to show' do
        expect { subject }.to change(Customer, :count).by(1)
        expect(response).to redirect_to(customer_path(Customer.last))
      end
    end

    context 'with invalid params' do
      let(:params) { { customer: { name: '' } } }

      it 're-renders the form with 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET #edit' do
    subject { get edit_customer_path(customer) }

    let(:customer) { create(:customer) }

    it 'renders the edit form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH #update' do
    subject { patch customer_path(customer), params: params }

    let(:customer) { create(:customer) }

    context 'with valid params' do
      let(:params) { { customer: { name: 'Updated Name' } } }

      it 'updates the customer and redirects' do
        subject
        expect(response).to redirect_to(customer_path(customer))
        expect(customer.reload.name).to eq('Updated Name')
      end
    end

    context 'with invalid params' do
      let(:params) { { customer: { name: '' } } }

      it 're-renders the form with 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
