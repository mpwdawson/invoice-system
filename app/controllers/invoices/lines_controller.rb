# frozen_string_literal: true

module Invoices
  class LinesController < ApplicationController
    before_action :set_invoice
    before_action :set_line, only: [:update, :destroy]

    # GET /invoices/:invoice_id/lines — lazy-loaded by the wizard's Step 3 frame
    def index
      render_lines
    end

    def create
      @invoice.invoice_lines.create(line_params.merge(sort_order: next_sort_order))
      render_lines
    end

    def update
      @line.update(line_params)
      render_lines
    end

    def destroy
      @line.destroy!
      render_lines
    end

    # PATCH /invoices/:invoice_id/lines/sort
    def sort
      params.expect(line_ids: []).each_with_index do |id, index|
        @invoice.invoice_lines.find(id).update(sort_order: index)
      end
      head :no_content
    end

    private

    def render_lines
      @lines = @invoice.invoice_lines.reload
      @new_line = InvoiceLine.new(invoice: @invoice)
      render :index, formats: [:html]
    end

    def next_sort_order
      (@invoice.invoice_lines.maximum(:sort_order) || -1) + 1
    end

    def set_invoice
      @invoice = Invoice.find(params.expect(:invoice_id))
    end

    def set_line
      @line = @invoice.invoice_lines.find(params.expect(:id))
    end

    def line_params
      params.expect(invoice_line: [:description, :task_id, :header])
    end
  end
end
