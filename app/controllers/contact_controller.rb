class ContactController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]

  def create
    # binding.pry
    skip_authorization
    recaptcha_valid = verify_recaptcha
Rails.logger.info "reCAPTCHA valid: #{recaptcha_valid}"
Rails.logger.info "reCAPTCHA errors: #{recaptcha_reply["error-codes"]}" unless recaptcha_valid || recaptcha_reply.nil?
    if user_signed_in? || verify_recaptcha
      @contact = contact_params
      ContactMailer.new_contact(@contact).deliver
      if user_signed_in?
        redirect_to dashboard_path, notice: "Merci pour votre message, nous vous répondrons dans les plus brefs délais"
      else
        redirect_to root_path, notice: "Merci pour votre message, nous vous répondrons dans les plus brefs délais"
      end
    elsif user_signed_in?
      redirect_to dashboard_path, notice: "Le CAPTCHA doit être validé"
    else
      redirect_to new_user_session_path, notice: "Le CAPTCHA doit être validé"
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:first_name, :last_name, :email, :school, :city, :message, :discovery_method)
  end
end
