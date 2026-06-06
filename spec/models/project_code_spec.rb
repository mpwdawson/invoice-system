require "rails_helper"

describe ProjectCode, type: :model do
  subject { build(:project_code) }

  describe "associations" do
    it { is_expected.to belong_to(:customer) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe "defaults" do
    it "is active by default" do
      project_code = build(:project_code)
      expect(project_code.active).to be(true)
    end
  end

  describe "scopes" do
    let(:customer)       { create(:customer) }
    let!(:active_code)   { create(:project_code, customer: customer, active: true) }
    let!(:inactive_code) { create(:project_code, customer: customer, active: false) }

    describe ".active" do
      it "includes active codes" do
        expect(ProjectCode.active).to include(active_code)
      end

      it "excludes inactive codes" do
        expect(ProjectCode.active).not_to include(inactive_code)
      end
    end

    describe ".ordered" do
      it "orders by code alphabetically" do
        codes = create_list(:project_code, 3, customer: customer)
        expect(ProjectCode.where(customer: customer).ordered.map(&:code)).to eq(
          ProjectCode.where(customer: customer).map(&:code).sort
        )
      end
    end
  end
end
