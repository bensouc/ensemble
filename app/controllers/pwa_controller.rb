# frozen_string_literal: true

# Le service worker, servi depuis la racine.
#
# Il doit venir de `/` et non de `/assets/…` : un service worker ne pilote que
# les pages situées sous SON chemin. Servi depuis le répertoire d'assets, il ne
# verrait jamais `/mobile/...`.
class PwaController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_after_action :verify_authorized, raise: false
  skip_after_action :verify_policy_scoped, raise: false
  # La protection CSRF refuse aussi tout JavaScript servi à un GET hors XHR,
  # contre l'inclusion par une balise <script> d'un autre site : le navigateur
  # qui enregistre le service worker tomberait dessus, et le hors-ligne avec.
  # Le script ne contient que des chemins d'assets, rien de privé à protéger.
  skip_forgery_protection

  def service_worker
    # Rails 7.1 n'a pas le générateur `app/views/pwa/` de Rails 8 : on rend le
    # gabarit à la main, avec le bon type MIME.
    expires_in 0, public: false, must_revalidate: true
    render template: "pwa/service_worker",
           formats: :js,
           layout: false,
           content_type: "text/javascript"
  end
end
