# frozen_string_literal: true

class ProjectCodesOverviewController < ApplicationController
  def index
    @customers = Customer.includes(project_codes: :tasks).order(:name)
  end
end
