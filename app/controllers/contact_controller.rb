class ContactController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]

  def create
    # binding.pry
    skip_authorization
    @contact = contact_params
    ContactMailer.new_contact(@contact).deliver
    redirect_to root_path, notice: "merci pour votre message, nous vous répondrons dans les plus brefs délais"
  end

  private

  def contact_params
    params.require(:contact).permit(:first_name, :last_name, :email, :school, :city, :message)
  end
end
