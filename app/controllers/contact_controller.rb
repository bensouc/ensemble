class ContactController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]

  def create
    # binding.pry
    skip_authorization
    @contact = contact_params
    ContactMailer.new_contact(@contact).deliver
    if user_signed_in?
      redirect_to dashboard_path, notice: "Merci pour votre message, nous vous répondrons dans les plus brefs délais"
    else
      redirect_to root_path, notice: "Merci pour votre message, nous vous répondrons dans les plus brefs délais"
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:first_name, :last_name, :email, :school, :city, :message)
  end
end
