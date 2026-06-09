# frozen_string_literal: true

class ProjectCodesController < ApplicationController
  before_action :set_customer
  before_action :set_project_code, only: [:show, :edit, :update, :archive, :destroy]

  def index
    @project_codes = @customer.project_codes.includes(:tasks).ordered
  end

  def show
    @tasks = @project_code.tasks.includes(:time_entries, :ticket_references).ordered
  end

  def new
    @project_code = @customer.project_codes.build
  end

  def edit; end

  def create
    @project_code = @customer.project_codes.build(project_code_params)
    if @project_code.save
      redirect_to customer_project_codes_path(@customer), notice: 'Project code added.'
    else
      render :new, formats: [:html], status: :unprocessable_content
    end
  end

  def update
    if @project_code.update(project_code_params)
      redirect_to customer_project_codes_path(@customer), notice: 'Project code updated.'
    else
      render :edit, formats: [:html], status: :unprocessable_content
    end
  end

  # PATCH /customers/:customer_id/project_codes/:id/archive — toggles active/inactive flag
  def archive
    @project_code.update!(active: !@project_code.active)
    redirect_to customer_project_codes_path(@customer)
  end

  def destroy
    if @project_code.destroy
      redirect_to customer_project_codes_path(@customer), notice: 'Project code deleted.'
    else
      redirect_to customer_project_codes_path(@customer),
                  alert: @project_code.errors.full_messages.to_sentence
    end
  end

  # GET /customers/:customer_id/project_codes/import_form — renders CSV textarea inside Turbo Frame
  def import_form; end

  # POST /customers/:customer_id/project_codes/import — bulk-creates codes from pasted CSV
  def import
    result = ProjectCodes::ImportService.call(customer: @customer, csv_text: params[:csv_text])

    if result.errors.any?
      @import_errors = result.errors
      render :import_form, status: :unprocessable_content
      return
    end

    parts = []
    parts << "#{result.created.size} created" if result.created.any?
    parts << "#{result.skipped.size} skipped (already exist)" if result.skipped.any?
    notice = parts.any? ? parts.join(', ') : 'Nothing to import'

    redirect_to customer_project_codes_path(@customer), notice:
  end

  private

  def set_customer
    @customer = Customer.find(params.expect(:customer_id))
  end

  def set_project_code
    @project_code = @customer.project_codes.find(params.expect(:id))
  end

  def project_code_params
    params.expect(project_code: [:code, :description])
  end
end
