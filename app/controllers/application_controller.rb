# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_unread_messages, if: :user_signed_in?
  include Pundit::Authorization
  # Pundit: allow-list approach
  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?

  def configure_permitted_parameters
    # For additional fields in app/views/devise/registrations/new.html.erb
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])

    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :avatar])
  end

  # Uncomment when you *really understand* Pundit!
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def user_not_authorized
    flash.now[:alert] = t("not_authorized")
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.prepend("flash", partial: "shared/flashes")
      end
      format.html { redirect_to(request.referrer || dashboard_path) }
    end
  end

  private

  def set_unread_messages
    @unread_messages = current_user.unread_message?
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end
end
