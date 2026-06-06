require "rails_helper"

describe "Customers", type: :request do
  before { post login_path, params: { password: "test_password" } }

  describe "GET /customers" do
    subject { get customers_path }

    it "renders the index" do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /customers/new" do
    subject { get new_customer_path }

    it "renders the new form" do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /customers" do
    subject { post customers_path, params: params }

    context "with valid params" do
      let(:params) { { customer: { name: "Argen", invoice_prefix: "ARGEN" } } }

      it "creates the customer and redirects to show" do
        expect { subject }.to change(Customer, :count).by(1)
        expect(response).to redirect_to(customer_path(Customer.last))
      end
    end

    context "with invalid params" do
      let(:params) { { customer: { name: "" } } }

      it "re-renders the form with 422" do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /customers/:id/edit" do
    let(:customer) { create(:customer) }
    subject { get edit_customer_path(customer) }

    it "renders the edit form" do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /customers/:id" do
    let(:customer) { create(:customer) }
    subject { patch customer_path(customer), params: params }

    context "with valid params" do
      let(:params) { { customer: { name: "Updated Name" } } }

      it "updates the customer and redirects" do
        subject
        expect(response).to redirect_to(customer_path(customer))
        expect(customer.reload.name).to eq("Updated Name")
      end
    end

    context "with invalid params" do
      let(:params) { { customer: { name: "" } } }

      it "re-renders the form with 422" do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
