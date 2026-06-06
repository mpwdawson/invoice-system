require "rails_helper"

describe "Sidebar navigation", type: :system do
  before { login }

  it "navigates to Tasks" do
    click_link "Tasks"
    expect(page).to have_current_path(tasks_path)
  end

  it "navigates to Customers" do
    click_link "Customers"
    expect(page).to have_current_path(customers_path)
  end

  it "navigates to Settings" do
    click_link "Settings"
    expect(page).to have_current_path(settings_path)
  end

  it "signs out" do
    click_button "Sign out"
    expect(page).to have_current_path(login_path)
  end
end
