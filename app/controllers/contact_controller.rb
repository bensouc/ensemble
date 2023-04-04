class ContactController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]

  def create
    # binding.pry
    @contact = contact_params
    ContactMailer.new_contact(@contact).deliver
    redirect_to root_path, notice: "merci pour votre message, nous vous répondrons dans les plus brefs délais"
  end

  private

  def contact_params
    params.require(:contact).permit(:nom, :email, :school, :city, :message)
  end
end
