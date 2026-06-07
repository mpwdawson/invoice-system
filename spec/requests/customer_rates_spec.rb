# frozen_string_literal: true

require 'rails_helper'

describe CustomerRatesController do
  before { post login_path, params: { password: 'test_password' } }

  let(:customer) { create(:customer) }

  describe 'POST #create' do
    subject { post customer_customer_rates_path(customer), params: params }

    context 'with valid params' do
      let(:params) { { customer_rate: { rate: '150.00', effective_from: '2026-01-01' } } }

      it 'creates a rate and redirects to the customer' do
        expect { subject }.to change(CustomerRate, :count).by(1)
        expect(response).to redirect_to(customer_path(customer))
      end
    end

    context 'with invalid params' do
      let(:params) { { customer_rate: { rate: '-10', effective_from: '' } } }

      it 'does not create a rate and redirects back with alert' do
        expect { subject }.not_to change(CustomerRate, :count)
        expect(response).to redirect_to(customer_path(customer))
      end
    end
  end

  describe 'GET #edit' do
    subject { get edit_customer_customer_rate_path(customer, rate) }

    let(:rate) { create(:customer_rate, customer: customer) }

    it 'renders the edit form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH #update' do
    subject { patch customer_customer_rate_path(customer, rate), params: params }

    let(:rate) { create(:customer_rate, customer: customer) }

    context 'with valid params' do
      let(:params) { { customer_rate: { rate: '200.00', effective_from: '2026-06-01' } } }

      it 'updates the rate and redirects to the customer' do
        subject
        expect(response).to redirect_to(customer_path(customer))
        expect(rate.reload.rate).to eq(200.00)
      end
    end

    context 'with invalid params' do
      let(:params) { { customer_rate: { rate: '-5', effective_from: '' } } }

      it 're-renders the form with 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:rate) { create(:customer_rate, customer: customer) }

    it 'destroys the rate and redirects to the customer' do
      expect do
        delete customer_customer_rate_path(customer, rate)
      end.to change(CustomerRate, :count).by(-1)
      expect(response).to redirect_to(customer_path(customer))
    end
  end
end
