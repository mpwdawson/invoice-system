require "rails_helper"

describe "Settings", type: :system do
  before { login }

  it "saves settings" do
    visit settings_path
    fill_in "Name", with: "Matt Dawson"
    fill_in "Email", with: "matt@example.com"
    click_button "Save"
    visit settings_path
    expect(page).to have_field("Name", with: "Matt Dawson")
  end
end
