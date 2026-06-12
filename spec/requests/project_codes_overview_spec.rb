# frozen_string_literal: true

require 'rails_helper'

describe ProjectCodesOverviewController do
  before { post login_path, params: { password: 'test_password' } }

  describe 'GET #index' do
    subject { get project_codes_path }

    let!(:customer)      { create(:customer) }
    let!(:active_code)   { create(:project_code, customer: customer, active: true) }
    let!(:archived_code) { create(:project_code, customer: customer, active: false) }

    it 'returns ok' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'shows all customers and their active codes' do
      subject
      expect(response.body).to include(customer.name)
      expect(response.body).to include(active_code.code)
    end

    it 'shows archived codes' do
      subject
      expect(response.body).to include(archived_code.code)
    end
  end
end
