# frozen_string_literal: true

module ApplicationHelper
  def sort_link(label, column, current_params)
    current_sort = current_params[:sort]
    current_dir  = current_params[:direction] || 'asc'
    new_dir      = (current_sort == column && current_dir == 'asc') ? 'desc' : 'asc'
    indicator    = current_sort == column ? (current_dir == 'asc' ? ' ▲' : ' ▼') : ''
    link_to "#{label}#{indicator}",
            tasks_path(current_params.merge(sort: column, direction: new_dir)),
            data: { turbo_frame: 'task-results' },
            class: 'hover:underline'
  end
end
