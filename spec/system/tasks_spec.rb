require "rails_helper"

describe "Tasks", type: :system do
  let!(:customer) { create(:customer, name: "Acme Corp") }

  before { login }

  it "creates a task" do
    visit new_task_path
    fill_in "Title", with: "Design homepage"
    select customer.name, from: "Customer"
    click_button "Create Task"
    expect(page).to have_content("Design homepage")
  end
end
