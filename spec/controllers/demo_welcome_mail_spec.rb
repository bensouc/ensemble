# frozen_string_literal: true

require "rails_helper"

# L'inscription produisait un seul courriel : la notification interne. L'enseignant,
# lui, n'entendait plus jamais parler de nous — ni tutos, ni limites de la démo,
# ni existence d'un abonnement.
RSpec.describe RegistrationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    create(:school, name: "Ensemble / DEMO")
    ActionMailer::Base.deliveries.clear
  end

  def inscrire(email: "camille@ecole.fr")
    post :create, params: { user: { first_name: "Camille", last_name: "Perrin", email:,
                                    password: "123456", discovery_method: "Bouche-à-oreille" } }
  end

  def bienvenue
    ActionMailer::Base.deliveries.find { |mail| mail.to == ["camille@ecole.fr"] }
  end

  it "accueille l'enseignant en plus de prévenir l'équipe" do
    inscrire
    expect(User.find_by(email: "camille@ecole.fr")).to be_present
    expect(bienvenue&.subject).to include("Bienvenue sur Ensemble")
  end

  # Le compte est déjà enregistré quand les courriels partent : une panne SMTP
  # renverrait l'enseignant sur la page d'erreur d'un compte qui, lui, existe.
  it "crée le compte même si l'envoi échoue" do
    allow(DemoMailer).to receive(:bienvenue).and_raise(Net::SMTPServerBusy, "serveur indisponible")
    inscrire
    expect(User.find_by(email: "camille@ecole.fr")).to be_present
    expect(response).to redirect_to(dashboard_path)
  end
end
