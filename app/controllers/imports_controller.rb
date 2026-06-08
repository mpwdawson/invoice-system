# frozen_string_literal: true

class ImportsController < ApplicationController
  def new
    @customers = Customer.order(:name)
  end

  def preview
    @customer      = Customer.find(params.expect(:customer_id))
    @text          = params[:text].to_s
    @preview       = Import::PreviewQuery.call(customer: @customer, text: @text)
    @project_codes = @customer.project_codes.active.ordered
  end

  def create
    @customer = Customer.find(params.expect(:customer_id))
    @text     = params[:text].to_s
    @result   = Import::CommitService.call(customer: @customer, text: @text, corrections: corrections_params)
  end

  private

  def corrections_params
    params.permit(corrections: [:key, :project_code_id])
      .fetch(:corrections, {})
      .values
      .map { |correction| { key: correction[:key], project_code_id: correction[:project_code_id].presence } }
  end
end
