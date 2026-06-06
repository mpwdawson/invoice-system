class ProjectCodesController < ApplicationController
  before_action :set_customer
  before_action :set_project_code, only: [ :edit, :update, :archive ]

  def index
    @project_codes = @customer.project_codes.ordered
  end

  def new
    @project_code = @customer.project_codes.build
  end

  def create
    @project_code = @customer.project_codes.build(project_code_params)
    if @project_code.save
      redirect_to customer_project_codes_path(@customer), notice: "Project code added."
    else
      render :new, formats: [ :html ], status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @project_code.update(project_code_params)
      redirect_to customer_project_codes_path(@customer), notice: "Project code updated."
    else
      render :edit, formats: [ :html ], status: :unprocessable_entity
    end
  end

  def archive
    @project_code.update!(active: !@project_code.active)
    redirect_to customer_project_codes_path(@customer)
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_project_code
    @project_code = @customer.project_codes.find(params[:id])
  end

  def project_code_params
    params.require(:project_code).permit(:code, :description)
  end
end
