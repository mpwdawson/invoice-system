class CustomerRatesController < ApplicationController
  before_action :set_customer
  before_action :set_rate, only: [ :edit, :update, :destroy ]

  def create
    @rate = @customer.customer_rates.build(customer_rate_params)
    if @rate.save
      redirect_to customer_path(@customer), notice: "Rate added."
    else
      redirect_to customer_path(@customer), alert: @rate.errors.full_messages.to_sentence
    end
  end

  def edit; end

  def update
    if @rate.update(customer_rate_params)
      redirect_to customer_path(@customer), notice: "Rate updated."
    else
      render :edit, formats: [ :html ], status: :unprocessable_entity
    end
  end

  def destroy
    @rate.destroy
    redirect_to customer_path(@customer), notice: "Rate deleted."
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_rate
    @rate = @customer.customer_rates.find(params[:id])
  end

  def customer_rate_params
    params.require(:customer_rate).permit(:rate, :effective_from)
  end
end
