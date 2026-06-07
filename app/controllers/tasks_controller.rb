# frozen_string_literal: true

class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :archive]

  def index
    @tasks = Tasks::SearchQuery.call(
      query: params[:query],
      customer_id: params[:customer_id],
      status: params[:status].presence || 'active',
      billable: params[:billable]
    )
    @customers = Customer.order(:name)
  end

  def show; end

  def new
    @task = Task.new
    load_form_data
  end

  def edit
    load_form_data
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to task_path(@task), notice: 'Task created.'
    else
      load_form_data
      render :new, formats: [:html], status: :unprocessable_content
    end
  end

  def update
    if @task.update(task_params)
      redirect_to task_path(@task), notice: 'Task updated.'
    else
      load_form_data
      render :edit, formats: [:html], status: :unprocessable_content
    end
  end

  def search
    @tasks = Tasks::SearchQuery.call(query: params[:query], status: 'active')
  end

  def archive
    @task.active? ? @task.archived! : @task.active!
    redirect_to tasks_path
  end

  private

  def set_task
    @task = Task.find(params.expect(:id))
  end

  def load_form_data
    @customers = Customer.order(:name)
    active_codes = ProjectCode.includes(:customer).active.ordered
    # When editing, keep the assigned code visible even if it was archived since assignment
    @project_codes = if @task&.project_code_id.present? && active_codes.none? { |pc| pc.id == @task.project_code_id }
                       active_codes.to_a + [@task.project_code]
                     else
                       active_codes
                     end
  end

  def task_params
    params.expect(task: [:customer_id, :project_code_id, :title,
                         :invoice_name, :notes, :billable])
  end
end
