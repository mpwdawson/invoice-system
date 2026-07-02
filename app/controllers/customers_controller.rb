# frozen_string_literal: true

class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update]

  def index
    @customers = Customer.includes(:customer_rates, :project_codes).order(:name)
  end

  def show
    @customer_rates = @customer.customer_rates.order(effective_from: :desc)
    @current_rate   = CustomerRate.current_for(@customer, user_date)
  end

  def new
    @customer = Customer.new
  end

  def edit; end

  def create
    @customer = Customer.new(customer_params)
    if @customer.save
      redirect_to customer_path(@customer), notice: 'Customer created.'
    else
      render :new, formats: [:html], status: :unprocessable_content
    end
  end

  def update
    if @customer.update(customer_params)
      redirect_to customer_path(@customer), notice: 'Customer updated.'
    else
      render :edit, formats: [:html], status: :unprocessable_content
    end
  end

  private

  def set_customer
    @customer = Customer.find(params.expect(:id))
  end

  def customer_params
    params.expect(customer: [:name, :address, :contact_name, :contact_email,
                             :invoice_prefix, :currency, :requires_project_codes])
  end
end
