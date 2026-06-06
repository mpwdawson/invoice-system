require "rails_helper"

describe "Customers", type: :system do
  before { login }

  it "creates a customer" do
    visit new_customer_path
    fill_in "Name", with: "Acme Corp"
    click_button "Create Customer"
    expect(page).to have_content("Acme Corp")
  end
end
