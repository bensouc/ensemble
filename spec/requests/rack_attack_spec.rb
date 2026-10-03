# frozen_string_literal: true

require "rails_helper"

# config/initializers/rack_attack.rb n'agit qu'en production, et ses compteurs
# vivent dans Rails.cache, c'est-à-dire Solid Cache. En test, Rails.cache est un
# :null_store qui ne compte rien : la spec branche un vrai Solid Cache, celui de
# la production, sur la table solid_cache_entries de la base de test.
RSpec.describe "Rack::Attack sur Solid Cache", type: :request do
  around do |exemple|
    Rack::Attack.enabled = true
    # Un espace de noms par exemple : `Rack::Attack.reset!` passe par
    # `delete_matched`, que Solid Cache ne fournit pas (la production n'en a pas
    # besoin).
    Rack::Attack.cache.store = SolidCache::Store.new(namespace: "rack_attack_spec_#{SecureRandom.hex(4)}")
    exemple.run
  ensure
    Rack::Attack.enabled = false
    Rack::Attack.cache.store = Rails.cache
  end

  def tenter_connexion(email = "personne@exemple.fr")
    post "/users/sign_in", params: { user: { email:, password: "mauvais" } },
                           headers: { "REMOTE_ADDR" => "203.0.113.7" }
  end

  it "laisse passer huit tentatives de connexion par minute, pas une de plus" do
    8.times { tenter_connexion }
    expect(response).not_to have_http_status(:too_many_requests)

    tenter_connexion
    expect(response).to have_http_status(:too_many_requests)
  end

  it "renvoie un 403 muet aux chemins de scanner" do
    get "/wp-login.php", headers: { "REMOTE_ADDR" => "203.0.113.8" }

    expect(response).to have_http_status(:forbidden)
  end

  # Rack::Attack s'arrête à la première liste de blocage qui répond : la règle
  # « bots: chemins de scan », déclarée avant, renvoie déjà 403 sur ces chemins,
  # si bien que le compteur de « fail2ban: scanners » n'est jamais incrémenté.
  # Le bannissement promis n'a jamais eu lieu, Redis ou pas. Signalé, à
  # corriger à part ; ce `pending` cassera dès que ce sera fait.
  it "bannit une heure l'adresse qui sonde trois chemins de scanner" do
    pending "fail2ban jamais atteint : la blocklist des chemins répond avant lui"

    %w[/wp-login.php /.env /xmlrpc.php].each do |chemin|
      get chemin, headers: { "REMOTE_ADDR" => "203.0.113.8" }
    end

    get "/", headers: { "REMOTE_ADDR" => "203.0.113.8" }
    expect(response).to have_http_status(:forbidden)

    get "/", headers: { "REMOTE_ADDR" => "203.0.113.9" }
    expect(response).to have_http_status(:ok)
  end
end
