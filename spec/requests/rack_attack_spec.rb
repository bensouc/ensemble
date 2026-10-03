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

  def sonder(chemins, headers)
    chemins.each { |chemin| get chemin, headers: }
  end

  let(:scans) { %w[/wp-login.php /.env /xmlrpc.php] }

  it "bannit une heure l'adresse qui sonde trois chemins de scanner" do
    sonder(scans, { "REMOTE_ADDR" => "203.0.113.8" })

    get "/", headers: { "REMOTE_ADDR" => "203.0.113.8" }
    expect(response).to have_http_status(:forbidden)

    get "/", headers: { "REMOTE_ADDR" => "203.0.113.9" }
    expect(response).to have_http_status(:ok)
  end

  it "ne bannit pas avant la troisième sonde" do
    sonder(scans.first(2), { "REMOTE_ADDR" => "203.0.113.10" })

    get "/", headers: { "REMOTE_ADDR" => "203.0.113.10" }
    expect(response).to have_http_status(:ok)
  end

  # En production, toutes les requêtes arrivent de Traefik, sur une adresse
  # privée du réseau Docker : bannir celle-là couperait l'app à tout le monde.
  it "derrière le proxy, ne bannit que le client qui sonde" do
    traefik = "172.18.0.5"
    sonder(scans, { "REMOTE_ADDR" => traefik, "HTTP_X_FORWARDED_FOR" => "198.51.100.20" })

    get "/", headers: { "REMOTE_ADDR" => traefik, "HTTP_X_FORWARDED_FOR" => "198.51.100.20" }
    expect(response).to have_http_status(:forbidden)

    get "/", headers: { "REMOTE_ADDR" => traefik, "HTTP_X_FORWARDED_FOR" => "198.51.100.21" }
    expect(response).to have_http_status(:ok)
  end
end
