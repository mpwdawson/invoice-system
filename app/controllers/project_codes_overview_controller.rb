# frozen_string_literal: true

class ProjectCodesOverviewController < ApplicationController
  def index
    @customers = Customer.includes(:project_codes).order(:name)
  end
end
