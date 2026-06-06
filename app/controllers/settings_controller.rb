class SettingsController < ApplicationController
  def edit
    @profile = ContractorProfile.first_or_initialize
  end

  def update
    @profile = ContractorProfile.first_or_initialize
    if @profile.update(profile_params)
      redirect_to settings_path, notice: "Settings saved."
    else
      render :edit, formats: [:html], status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:contractor_profile).permit(:name, :address, :email, :tax_number, :bank_details)
  end
end
