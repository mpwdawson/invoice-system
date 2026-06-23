# frozen_string_literal: true

class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy, :archive, :update_inline]

  def index
    @tasks = Tasks::SearchQuery.call(
      query:           params[:query],
      customer_id:     params[:customer_id],
      project_code_id: params[:project_code_id],
      date_from:       params[:date_from],
      status:          params[:status].presence || 'active',
      billable:        params[:billable],
      sort:            params[:sort],
      direction:       params[:direction]
    ).select("tasks.*, COALESCE((SELECT SUM(hours) FROM time_entries WHERE time_entries.task_id = tasks.id), 0) AS total_hours")
    @customers     = Customer.order(:name)
    @project_codes = ProjectCode.active.ordered
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

  # GET /tasks/search — Turbo Frame autocomplete dropdown
  def search
    @query       = params[:query]
    @customer_id = params[:customer_id].presence
    @tasks = Tasks::SearchQuery.call(query: @query, status: 'active', customer_id: @customer_id).limit(15)
  end

  # GET /tasks/inline_new — compact create form inside the Log Time search dropdown
  def inline_new
    @task = Task.new(title: params[:title], customer_id: params[:customer_id])
    load_form_data
  end

  # POST /tasks/inline_create — creates task and returns auto-select slot for the entry form
  def inline_create
    @task = Task.new(inline_task_params)
    if @task.save
      if params[:ticket_ref].present?
        parsed = Tasks::ParseTicketRefsService.call(input: params[:ticket_ref])
        parsed.each { |ref| @task.ticket_references.find_or_create_by(ref) }
      end
    else
      load_form_data
      render :inline_new, formats: [:html], status: :unprocessable_content
    end
  end

  # PATCH /tasks/:id/update_inline
  def update_inline
    if @task.update(update_inline_task_params)
      head :ok
    else
      head :unprocessable_content
    end
  end

  def destroy
    if @task.destroy
      redirect_to tasks_path, notice: 'Task deleted.'
    else
      redirect_to edit_task_path(@task), alert: @task.errors.full_messages.to_sentence
    end
  end

  # PATCH /tasks/:id/archive
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

  def update_inline_task_params
    params.expect(task: [:title])
  end

  def inline_task_params
    params.expect(task: [:title, :customer_id, :project_code_id])
  end
end
