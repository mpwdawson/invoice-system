# frozen_string_literal: true

class TicketReferencesController < ApplicationController
  before_action :set_task

  def create
    parsed = Tasks::ParseTicketRefsService.call(input: params[:input])
    parsed.each { |ref| @task.ticket_references.find_or_create_by(ref) }
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to task_path(@task) }
    end
  end

  def destroy
    @ticket_reference = @task.ticket_references.find(params.expect(:id))
    @ticket_reference.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to task_path(@task) }
    end
  end

  private

  def set_task
    @task = Task.find(params.expect(:task_id))
  end
end
