# frozen_string_literal: true

# Contrôleur de base du tableau de bord des jobs (Mission Control, sur /jobs).
#
# Pas ApplicationController : ses `after_action` Pundit (`verify_authorized`)
# lèveraient sur des actions que la gem ne connaît pas. Pas non plus
# ActionController::Base nu : sans `config.load_defaults`, rien n'y vérifie le
# jeton CSRF, et les boutons « relancer » et « supprimer » seraient exposés.
#
# La route est déjà réservée aux admins (config/routes.rb) ; ce contrôleur
# double la garde. `current_user` est ici celui de Devise, donc l'admin même
# pendant une personnification : pretender ne le remplace que dans
# ApplicationController.
class JobsDashboardController < ActionController::Base # rubocop:disable Rails/ApplicationController
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
  before_action :reserve_aux_admins

  private

  def reserve_aux_admins
    head :forbidden unless current_user.admin?
  end
end
