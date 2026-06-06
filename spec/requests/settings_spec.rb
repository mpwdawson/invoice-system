# frozen_string_literal: true

require 'rails_helper'

describe 'Settings' do
  before { post login_path, params: { password: 'test_password' } }

  describe 'GET /settings' do
    subject { get settings_path }

    it 'renders the settings form' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /settings' do
    subject { patch settings_path, params: params }

    context 'with valid params' do
      let(:params) { { contractor_profile: { name: 'Matt Dawson', email: 'matt@example.com' } } }

      it 'saves the profile and redirects' do
        subject
        expect(response).to redirect_to(settings_path)
        expect(ContractorProfile.first.name).to eq('Matt Dawson')
      end
    end

    context 'when updating an existing profile with valid params' do
      before { create(:contractor_profile, name: 'Old Name', email: 'old@example.com') }

      let(:params) { { contractor_profile: { name: 'Matt Dawson', email: 'matt@example.com' } } }

      it 'updates the existing profile without creating a second' do
        subject
        expect(ContractorProfile.count).to eq(1)
        expect(ContractorProfile.first.name).to eq('Matt Dawson')
      end
    end

    context 'with invalid params' do
      let(:params) { { contractor_profile: { name: '', email: '' } } }

      it 're-renders the form with 422' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
