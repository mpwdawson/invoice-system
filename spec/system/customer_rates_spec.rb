require "rails_helper"

describe "CustomerRates", type: :system do
  let(:customer) { create(:customer) }

  before { login }

  it "adds a rate from the customer show page" do
    visit customer_path(customer)
    fill_in "Rate ($/hr)", with: "150"
    fill_in "Effective From", with: "2026-01-01"
    click_button "Add Rate"
    expect(page).to have_content("$150.00")
  end
end
