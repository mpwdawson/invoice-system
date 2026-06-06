class SessionsController < ApplicationController
  skip_before_action :require_login

  def new; end

  def create
    if secure_token_compare(password_digest, params[:password].to_s)
      session[:authenticated] = true
      redirect_to root_path, notice: "Signed in."
    else
      flash.now[:alert] = "Invalid password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:authenticated] = nil
    redirect_to login_path, notice: "Signed out."
  end

  private

  def password_digest
    ENV.fetch("APP_PASSWORD_DIGEST")
  end

  def secure_token_compare(digest, password)
    ActiveSupport::SecurityUtils.secure_compare(
      digest,
      ::Digest::SHA256.hexdigest(password)
    )
  end
end
