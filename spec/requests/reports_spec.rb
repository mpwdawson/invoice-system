# frozen_string_literal: true

require 'rails_helper'

describe ReportsController do
  before { post login_path, params: { password: 'test_password' } }

  describe 'GET #monthly_hours' do
    subject { get monthly_hours_report_path }

    it 'returns ok' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #monthly_hours (CSV)' do
    subject do
      get monthly_hours_report_path(
        format: :csv,
        customer_id: customer.id,
        from: Date.current.beginning_of_month,
        to: Date.current.end_of_month
      )
    end

    let(:customer) { create(:customer) }

    it 'returns a CSV response' do
      subject
      expect(response.media_type).to eq('text/csv')
    end
  end
end
