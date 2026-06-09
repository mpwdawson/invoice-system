# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_timezone, :user_date

  private

  def require_login
    redirect_to login_path unless session[:authenticated]
  end

  def current_timezone
    @current_timezone ||= ContractorProfile.first&.timezone.presence || 'UTC'
  end

  def user_date
    @user_date ||= Time.use_zone(current_timezone) { Date.current }
  end
end
