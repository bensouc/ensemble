# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Le service worker", type: :request do
  before { get service_worker_path }

  # Il doit être joignable sans être connecté : l'enregistrement a lieu au
  # chargement de n'importe quelle page, y compris celle de connexion.
  it "se sert sans authentification" do
    expect(response).to have_http_status(:ok)
  end

  it "s'annonce comme du JavaScript" do
    expect(response.media_type).to eq("text/javascript")
  end

  # Servi depuis la racine, pas depuis /assets/ : un service worker ne pilote
  # que les pages situées sous son propre chemin.
  it "est servi depuis la racine" do
    expect(service_worker_path).to eq("/service-worker.js")
  end

  it "sépare le cache de la coque de celui des données" do
    expect(response.body).to include("ensemble-coque-", "ensemble-donnees-")
  end

  it "précharge la coque avec les empreintes des assets" do
    expect(response.body).to match(%r{/assets/application-[a-f0-9]+\.js})
    expect(response.body).to match(%r{/assets/application-[a-f0-9]+\.css})
  end

  # Le nom des caches porte l'empreinte du bundle : un déploiement invalide donc
  # les anciens, sans quoi les enseignants garderaient une coque périmée.
  it "change de version avec le bundle" do
    empreinte = response.body[/const VERSION = "([^"]+)"/, 1]

    expect(empreinte).to include(ActionController::Base.helpers.asset_digest_path("application.js"))
  end
end
