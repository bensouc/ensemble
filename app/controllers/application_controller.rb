# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # `current_user` renvoie l'utilisateur incarné, `true_user` reste l'admin :
  # Warden ne déconnecte jamais l'admin, seule la session porte l'id incarné.
  # Doit rester APRÈS l'inclusion des helpers Devise (donc ici, en tête de classe)
  # car la gem aliase le `current_user` existant.
  impersonates :user

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_unread_messages, if: :user_signed_in?
  before_action :forbid_sensitive_action_while_impersonating
  include Pundit::Authorization

  helper_method :impersonating?

  # Ces actions engagent le vrai compte de l'enseignant, hors de portée d'un
  # retour arrière depuis l'app : la facturation Stripe (le portail permet de
  # résilier l'abonnement d'un client payant) et ses identifiants de connexion.
  # `:all` ferme le contrôleur entier.
  FORBIDDEN_WHILE_IMPERSONATING = {
    "stripe/stripe" => :all,
    "subscriptions" => %w[new create],
    "registrations" => %w[edit update destroy]
  }.freeze

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

  # `flash.now` ne survit pas à une redirection : la branche HTML renvoyait
  # l'utilisateur en arrière sans lui dire pourquoi.
  def user_not_authorized
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = t("not_authorized")
        render turbo_stream: turbo_stream.prepend("flash", partial: "shared/flashes")
      end
      format.html { redirect_to(request.referer || dashboard_path, alert: t("not_authorized")) }
    end
  end

  # Naviguer sous l'identité d'un autre : l'admin connecté reste `true_user`.
  def impersonating?
    current_user != true_user
  end

  private

  def forbid_sensitive_action_while_impersonating
    return unless impersonating?

    forbidden = FORBIDDEN_WHILE_IMPERSONATING[controller_path]
    return if forbidden.nil?
    return unless forbidden == :all || forbidden.include?(action_name)

    redirect_back fallback_location: dashboard_path,
                  alert: "Action indisponible pendant une personnification : revenez sur votre compte d'abord."
  end

  # `devise_last_seen` tamponne `last_seen` sur `current_user` à chaque requête.
  # Pendant une personnification, ce serait de la fausse activité inscrite sur le
  # compte incarné — et cette date sert justement à savoir qui utilise l'app.
  def track_last_seen
    super unless impersonating?
  end

  def set_unread_messages
    @unread_messages = current_user.unread_message?
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end
end
