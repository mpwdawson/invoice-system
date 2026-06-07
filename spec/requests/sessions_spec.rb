# frozen_string_literal: true

require 'rails_helper'

describe SessionsController do
  let(:correct_password) { 'test_password' }
  let(:wrong_password)   { 'wrong' }

  describe 'GET /' do
    context 'without a session' do
      it 'redirects to login' do
        get '/'
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'POST #create' do
    context 'with the correct password' do
      it 'sets the session and redirects' do
        post login_path, params: { password: correct_password }
        expect(session[:authenticated]).to be true
        expect(response).to be_redirect
      end
    end

    context 'with the wrong password' do
      it 'does not set the session and re-renders login' do
        post login_path, params: { password: wrong_password }
        expect(session[:authenticated]).to be_nil
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE #destroy' do
    before { post login_path, params: { password: correct_password } }

    it 'clears the session and redirects to login' do
      delete logout_path
      expect(session[:authenticated]).to be_nil
      expect(response).to redirect_to(login_path)
    end
  end
end
