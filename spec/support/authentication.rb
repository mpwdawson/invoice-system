module AuthenticationHelpers
  def login
    visit login_path
    fill_in "Password", with: "test_password"
    click_button "Sign in"
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :system
end
