# frozen_string_literal: true

require "rails_helper"

# Sur la charge utile réelle d'un abonnement sur facture — collection_method
# "send_invoice", sans période d'essai. C'est le cas qui faisait tomber le module :
# `Time.at(nil)` sur `trial_end`.
RSpec.describe Stripesubscription do
  let(:event) { evenement_stripe("customer_subscription_created") }
  let(:objet) { event.data.object }
  let(:school) { create(:school, stripe_customer_id: objet.customer) }

  describe ".update_or_create" do
    context "quand l'école n'a pas encore d'abonnement" do
      # `school` est un `let` paresseux : sans ça, l'école n'existe pas encore au
      # moment où le module cherche le client Stripe.
      before { school }

      # Le module ne savait qu'updater : `school.subscription` étant nil,
      # `nil.update!` levait. D'où les abonnements saisis à la main.
      it "crée la ligne au lieu de lever" do
        expect { described_class.update_or_create(event) }.to change(Subscription, :count).by(1)
      end

      it "reprend les champs de l'abonnement Stripe" do
        described_class.update_or_create(event)
        abo = school.reload.subscription

        expect(abo.stripe_subscription_id).to eq(objet.id)
        expect(abo.status).to eq("active")
        expect(abo.quantity).to eq(1)
        expect(abo.plan_id).to eq(objet.items.data[0].price.id)
        expect(abo.cancel_at_period_end).to be false
      end

      # Un abonnement sur facture n'a pas d'essai : `trial_end` est nul.
      it "accepte une absence de période d'essai" do
        expect { described_class.update_or_create(event) }.not_to raise_error
        expect(school.reload.subscription.trial_end).to be_nil
      end

      # Le portail Stripe ne sait pas modifier un abonnement sur facture : sans ce
      # champ, l'app proposait « Ajouter une classe à mon abonnement » à une école
      # dont le portail ne sait que résilier.
      it "retient le mode de recouvrement" do
        described_class.update_or_create(event)
        abo = school.reload.subscription

        expect(abo.collection_method).to eq("send_invoice")
        expect(abo).to be_sur_facture
      end

      # `rythm` n'était jamais renseigné, et le défaut de la base viole sa validation.
      it "déduit le rythme de l'intervalle du prix" do
        described_class.update_or_create(event)
        expect(school.reload.subscription.rythm).to eq("Annuel")
      end

      it "reprend la période de facturation" do
        described_class.update_or_create(event)
        abo = school.reload.subscription
        expect(abo.current_period_start).to eq(Time.zone.at(objet.current_period_start).to_date)
        expect(abo.current_period_end).to eq(Time.zone.at(objet.current_period_end).to_date)
      end
    end

    context "quand l'école a déjà une ligne saisie à la main" do
      # Le cas d'Alain Fournier : ligne existante, stripe_subscription_id vide.
      let!(:ligne) do
        Subscription.create!(school:, status: "active", quantity: 10, rythm: "Annuel",
                             current_period_start: Date.new(2026, 1, 1),
                             current_period_end: Date.new(2026, 12, 31))
      end

      it "l'adopte sans en créer une seconde" do
        expect { described_class.update_or_create(event) }.not_to change(Subscription, :count)
        expect(ligne.reload.stripe_subscription_id).to eq(objet.id)
      end

      it "aligne la quantité sur celle de Stripe" do
        described_class.update_or_create(event)
        expect(ligne.reload.quantity).to eq(1)
      end
    end

    context "quand le client Stripe est inconnu" do
      # `School.find_by(...)` renvoyait nil, puis `nil.subscription` levait.
      it "n'écrit rien et ne lève pas" do
        expect { described_class.update_or_create(event) }.not_to change(Subscription, :count)
        expect(described_class.update_or_create(event)).to be_nil
      end
    end

    # Un enum lève ArgumentError sur une valeur inconnue : ces deux statuts
    # manquaient et faisaient répondre 500 au webhook.
    %w[incomplete_expired paused].each do |statut|
      it "accepte le statut #{statut}" do
        school
        objet.status = statut
        expect(described_class.update_or_create(event)).to be_present
        expect { described_class.update_or_create(event) }.not_to raise_error
        expect(school.reload.subscription.status).to eq(statut)
      end
    end
  end

  describe ".delete" do
    it "supprime la ligne correspondante" do
      school
      expect(described_class.update_or_create(event)).to be_present
      expect { described_class.delete(objet.id) }.to change(Subscription, :count).by(-1)
    end

    # Stripe peut annoncer la fin d'un abonnement jamais synchronisé ici.
    it "ne lève pas sur un identifiant inconnu" do
      expect { described_class.delete("sub_inconnu") }.not_to raise_error
    end
  end
end
