require "rails_helper"

describe "CustomerRates", type: :request do
  before { post login_path, params: { password: "test_password" } }

  let(:customer) { create(:customer) }

  describe "POST /customers/:customer_id/customer_rates" do
    subject { post customer_customer_rates_path(customer), params: params }

    context "with valid params" do
      let(:params) { { customer_rate: { rate: "150.00", effective_from: "2026-01-01" } } }

      it "creates a rate and redirects to the customer" do
        expect { subject }.to change(CustomerRate, :count).by(1)
        expect(response).to redirect_to(customer_path(customer))
      end
    end

    context "with invalid params" do
      let(:params) { { customer_rate: { rate: "-10", effective_from: "" } } }

      it "does not create a rate and redirects back with alert" do
        expect { subject }.not_to change(CustomerRate, :count)
        expect(response).to redirect_to(customer_path(customer))
      end
    end
  end

  describe "GET /customers/:customer_id/customer_rates/:id/edit" do
    let(:rate) { create(:customer_rate, customer: customer) }
    subject { get edit_customer_customer_rate_path(customer, rate) }

    it "renders the edit form" do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /customers/:customer_id/customer_rates/:id" do
    let(:rate) { create(:customer_rate, customer: customer) }
    subject { patch customer_customer_rate_path(customer, rate), params: params }

    context "with valid params" do
      let(:params) { { customer_rate: { rate: "200.00", effective_from: "2026-06-01" } } }

      it "updates the rate and redirects to the customer" do
        subject
        expect(response).to redirect_to(customer_path(customer))
        expect(rate.reload.rate).to eq(200.00)
      end
    end

    context "with invalid params" do
      let(:params) { { customer_rate: { rate: "-5", effective_from: "" } } }

      it "re-renders the form with 422" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /customers/:customer_id/customer_rates/:id" do
    let!(:rate) { create(:customer_rate, customer: customer) }

    it "destroys the rate and redirects to the customer" do
      expect {
        delete customer_customer_rate_path(customer, rate)
      }.to change(CustomerRate, :count).by(-1)
      expect(response).to redirect_to(customer_path(customer))
    end
  end
end
