# frozen_string_literal: true

require "rails_helper"

# Le webhook est le seul écrivain de `Subscription` en production, et n'avait
# aucun test. Ni webmock ni VCR au Gemfile : on construit l'événement en mémoire
# et on neutralise la vérification de signature, comme le fait déjà
# spec/controllers/impersonations_controller_spec.rb pour le portail Stripe.
RSpec.describe "Webhook Stripe", type: :request do
  let(:event) { evenement_stripe("customer_subscription_created") }

  def poster(corps = "{}")
    post "/stripe-webhooks", params: corps, headers: { "HTTP_STRIPE_SIGNATURE" => "t=1,v1=peu_importe" }
  end

  context "signature invalide" do
    before do
      erreur = Stripe::SignatureVerificationError.new("nope", "sig")
      allow(Stripe::Webhook).to receive(:construct_event).and_raise(erreur)
    end

    # `status 400` puis `return` finissait en 500 — que Stripe rejoue trois jours
    # durant, sans espoir d'aboutir.
    it "répond 400, pas 500" do
      poster
      expect(response).to have_http_status(:bad_request)
    end
  end

  context "charge utile illisible" do
    before { allow(Stripe::Webhook).to receive(:construct_event).and_raise(JSON::ParserError) }

    it "répond 400" do
      poster
      expect(response).to have_http_status(:bad_request)
    end
  end

  context "abonnement créé" do
    let!(:school) { create(:school, stripe_customer_id: event.data.object.customer) }

    before { allow(Stripe::Webhook).to receive(:construct_event).and_return(event) }

    it "crée la ligne locale et acquitte" do
      expect { poster }.to change(Subscription, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(school.reload.subscription.stripe_subscription_id).to eq(event.data.object.id)
    end
  end

  context "événement d'un type non traité" do
    let(:autre) { Stripe::Event.construct_from(id: "evt_x", type: "invoice.created", data: { object: {} }) }

    before { allow(Stripe::Webhook).to receive(:construct_event).and_return(autre) }

    it "acquitte sans rien faire" do
      expect { poster }.not_to change(Subscription, :count)
      expect(response).to have_http_status(:ok)
    end
  end

  # `ActiveRecordError` ne distinguait pas : `RecordInvalid` en hérite, donc une
  # validation qui échoue — définitive — déclenchait trois jours de rejeux.
  context "quand la panne est définitive" do
    let!(:school) { create(:school, stripe_customer_id: event.data.object.customer) }

    before do
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(Stripesubscription).to receive(:update_or_create)
        .and_raise(ActiveRecord::RecordInvalid.new(Subscription.new))
    end

    it "acquitte au lieu de faire rejouer Stripe" do
      poster
      expect(response).to have_http_status(:ok)
    end
  end

  context "quand la panne est passagère" do
    let!(:school) { create(:school, stripe_customer_id: event.data.object.customer) }

    before do
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(Stripesubscription).to receive(:update_or_create).and_raise(Stripe::APIConnectionError)
    end

    # Elle doit remonter : Stripe rejouera, et cette fois ça peut aboutir.
    it "laisse l'erreur remonter" do
      expect { poster }.to raise_error(Stripe::APIConnectionError)
    end
  end

  context "quand un gestionnaire lève" do
    before do
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(Stripesubscription).to receive(:update_or_create).and_raise("bavure")
    end

    # Acquitter plutôt que 500 : une charge utile qu'on ne sait pas traiter ne
    # doit pas déclencher trois jours de rejeux.
    it "journalise et acquitte" do
      expect(Rails.logger).to receive(:error).with(/bavure/)
      poster
      expect(response).to have_http_status(:ok)
    end
  end
end
