# frozen_string_literal: true

require "rails_helper"

# Une école dont le client Stripe a été supprimé depuis le Dashboard garde son
# `stripe_customer_id` en base. Ouvrir le portail échoue alors en 400
# `resource_missing`, et l'action rendait une 500 — vu en production sur une
# école passée au règlement par virement, dont le client avait été nettoyé.
RSpec.describe "Portail de facturation Stripe", type: :request do
  let(:school) { create(:school, stripe_customer_id: id_en_base) }
  let(:responsable) { create(:user, admin: false, demo: false) }
  let(:portail) do
    Stripe::BillingPortal::Session.construct_from(id: "bps_1", url: "https://billing.stripe.com/session")
  end

  # Un vrai objet Stripe, pas un double : Pundit lit `record.class` pour trouver
  # la policy. Et le stub refuse le client supprimé comme le fait Stripe, sinon
  # la spec passerait tout autant sur la version qui rendait une 500.
  before do
    school.add_teacher(responsable, true)
    sign_in responsable.reload
    allow(Stripe::BillingPortal::Session).to receive(:create) do |params|
      raise inconnu_chez_stripe(params[:customer]) if params[:customer] == "cus_supprime"

      portail
    end
    allow(Stripe::Customer).to receive(:create)
      .and_return(Stripe::Customer.construct_from(id: "cus_neuf", email: school.email))
  end

  def inconnu_chez_stripe(id)
    Stripe::InvalidRequestError.new("No such customer: '#{id}'", "customer", code: "resource_missing")
  end

  def abonner(school)
    school.create_subscription!(status: "active", rythm: "Annuel", quantity: 3,
                                current_period_start: Date.new(2025, 9, 1),
                                current_period_end: Date.new(2026, 8, 31))
  end

  context "quand le client Stripe existe" do
    let(:id_en_base) { "cus_valide" }

    before { get "/create-customer-portal-session" }

    it "renvoie vers le portail" do
      expect(response).to redirect_to("https://billing.stripe.com/session")
    end

    it "ouvre la session sur ce client" do
      expect(Stripe::BillingPortal::Session).to have_received(:create)
        .with(hash_including(customer: "cus_valide"))
    end

    # Le chemin courant ne coûte qu'un appel : pas de vérification préalable du
    # client, et donc rien à créer.
    it "ne touche pas aux clients" do
      expect(Stripe::Customer).not_to have_received(:create)
    end
  end

  context "quand le client Stripe a été supprimé" do
    let(:id_en_base) { "cus_supprime" }

    # `retrieve` répond 200 sur un client supprimé, avec `deleted: true` : c'est
    # ce que la réparation de l'id doit savoir reconnaître.
    before do
      allow(Stripe::Customer).to receive(:retrieve)
        .and_return(Stripe::Customer.construct_from(id: "cus_supprime", deleted: true))
    end

    context "et que l'école a un abonnement" do
      before do
        abonner(school)
        get "/create-customer-portal-session"
      end

      it "ne rend pas d'erreur serveur" do
        expect(response.status).to be < 500
      end

      it "renvoie l'école en arrière avec un message" do
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to include("n'est pas géré depuis Stripe")
      end

      # Sans quoi la seule issue serait une intervention en console : c'est cet id
      # réparé qui permet de rattacher l'abonnement depuis le Dashboard.
      it "remplace l'id périmé par celui du client neuf" do
        expect(school.reload.stripe_customer_id).to eq("cus_neuf")
      end

      # Le portail d'un client neuf est vide : ni abonnement ni facture. L'ouvrir
      # dirait à l'école que tout va bien. La seule tentative est celle qui a
      # échoué, sur l'id périmé.
      it "ne retente pas le portail sur le client neuf" do
        expect(Stripe::BillingPortal::Session).to have_received(:create).once
        expect(Stripe::BillingPortal::Session).not_to have_received(:create)
          .with(hash_including(customer: "cus_neuf"))
      end
    end

    context "et que l'école n'a pas d'abonnement" do
      before { get "/create-customer-portal-session" }

      it "l'envoie souscrire" do
        expect(response).to redirect_to(new_subscription_path)
        expect(flash[:alert]).to include("Souscrivez un abonnement")
      end
    end
  end

  # Le menu propose le portail sur la seule foi d'un abonnement actif, sans
  # regarder s'il existe un client : une ligne saisie à la main dans `/admin`
  # suffit à y arriver sans id du tout.
  context "quand l'école n'a aucun client Stripe" do
    let(:id_en_base) { nil }

    before do
      abonner(school)
      get "/create-customer-portal-session"
    end

    it "n'appelle pas Stripe pour rien" do
      expect(Stripe::BillingPortal::Session).not_to have_received(:create)
      expect(response).to redirect_to(dashboard_path)
    end

    it "crée le client qui manquait" do
      expect(school.reload.stripe_customer_id).to eq("cus_neuf")
    end
  end

  # Le portail non configuré dans le Dashboard lève la même classe d'erreur avec
  # un autre code. L'avaler en message d'interface ferait disparaître la
  # notification d'exception, seule alerte sur une panne de configuration.
  context "quand Stripe échoue pour une autre raison" do
    let(:id_en_base) { "cus_valide" }

    before do
      allow(Stripe::BillingPortal::Session).to receive(:create).and_raise(
        Stripe::InvalidRequestError.new("No configuration provided", nil, code: "parameter_missing")
      )
    end

    it "laisse remonter l'erreur" do
      expect { get "/create-customer-portal-session" }.to raise_error(Stripe::InvalidRequestError)
    end
  end
end
