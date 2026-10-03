# frozen_string_literal: true

require "rails_helper"

# Mission Control (/jobs) remplace le tableau de bord de Sidekiq : réservé aux
# admins, et ses boutons d'action protégés par le jeton CSRF.
RSpec.describe "Tableau de bord des jobs", type: :request do
  it "renvoie un visiteur vers la connexion" do
    get "/jobs"

    expect(response).to redirect_to("/users/sign_in")
  end

  it "reste introuvable pour un enseignant" do
    sign_in create(:user, admin: false)

    expect { get "/jobs" }.to raise_error(ActionController::RoutingError)
  end

  # La page elle-même liste les files de Solid Queue, que les specs de requête
  # remplacent par l'adaptateur :test d'ActiveJob : on vérifie que l'admin
  # franchit les gardes et atteint Mission Control. L'affichage réel se vérifie
  # sur le serveur de développement.
  it "laisse passer un admin jusqu'à Mission Control" do
    allow_any_instance_of(MissionControl::Jobs::QueuesController).
      to receive(:index) { |controleur| controleur.head(:ok) }
    sign_in create(:user, admin: true)

    get "/jobs"
    follow_redirect! while response.redirect?

    expect(response).to have_http_status(:ok)
  end

  it "s'appuie sur un contrôleur qui vérifie le jeton CSRF" do
    expect(MissionControl::Jobs::ApplicationController.ancestors).to include(JobsDashboardController)
    expect(JobsDashboardController._process_action_callbacks.map(&:filter)).to include(:verify_authenticity_token)
  end
end
