# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeHelper do
  let(:school) { create(:school, name: "École Alain-Fournier", email: "ecole@exemple.fr") }
  let(:client_neuf) { Stripe::Customer.construct_from(id: "cus_neuf", email: school.email) }

  before { allow(Stripe::Customer).to receive(:create).and_return(client_neuf) }

  describe ".get_or_create_customer" do
    context "sans id en base" do
      before { described_class.get_or_create_customer(school) }

      it "enregistre l'id du client créé" do
        expect(school.reload.stripe_customer_id).to eq("cus_neuf")
      end

      # Un client qui n'a qu'un email est introuvable dans le Dashboard, où
      # l'abonnement sur facture se crée à la main.
      it "nomme le client et y attache l'id de l'école" do
        expect(Stripe::Customer).to have_received(:create)
          .with(hash_including(email: "ecole@exemple.fr",
                               name: "École Alain-Fournier",
                               metadata: { "school" => school.id }))
      end
    end

    context "avec un id que Stripe connaît" do
      let(:school) { create(:school, stripe_customer_id: "cus_connu") }
      let(:existant) { Stripe::Customer.construct_from(id: "cus_connu", email: school.email) }

      before { allow(Stripe::Customer).to receive(:retrieve).and_return(existant) }

      it "renvoie ce client sans en créer un autre" do
        expect(described_class.get_or_create_customer(school)).to eq(existant)
        expect(Stripe::Customer).not_to have_received(:create)
      end

      it "laisse l'id en base intact" do
        described_class.get_or_create_customer(school)
        expect(school.reload.stripe_customer_id).to eq("cus_connu")
      end

      # Un client vivant ne porte pas la clé `deleted` : elle se lit nil, et ne
      # doit pas le faire passer pour supprimé.
      it "ne prend pas un client vivant pour un client supprimé" do
        expect(existant[:deleted]).to be_nil
        expect(described_class.get_or_create_customer(school)).to eq(existant)
      end
    end

    # Le cas vu en production. Stripe répond **200** sur un client supprimé, avec
    # un objet réduit à `{ id:, deleted: true }` : un `rescue` ne voit rien passer,
    # et l'ancienne version rendait ce client mort en gardant l'id en base.
    context "avec un id dont le client a été supprimé" do
      let(:school) { create(:school, stripe_customer_id: "cus_supprime") }

      before do
        allow(Stripe::Customer).to receive(:retrieve)
          .and_return(Stripe::Customer.construct_from(id: "cus_supprime", deleted: true))
      end

      it "ne rend jamais le client supprimé" do
        expect(described_class.get_or_create_customer(school)).to eq(client_neuf)
      end

      it "remplace l'id du client supprimé" do
        described_class.get_or_create_customer(school)
        expect(school.reload.stripe_customer_id).to eq("cus_neuf")
      end
    end

    # L'autre forme d'échec : un id que Stripe ne connaît pas du tout — jamais
    # créé, ou créé en test mode et lu en live. Là, c'est un 404.
    context "avec un id que Stripe ne connaît pas" do
      let(:school) { create(:school, stripe_customer_id: "cus_inconnu") }

      before do
        allow(Stripe::Customer).to receive(:retrieve).and_raise(
          Stripe::InvalidRequestError.new("No such customer: 'cus_inconnu'", "customer", code: "resource_missing")
        )
      end

      it "en crée un neuf plutôt que de laisser remonter l'erreur" do
        expect(described_class.get_or_create_customer(school)).to eq(client_neuf)
      end

      it "remplace l'id périmé" do
        described_class.get_or_create_customer(school)
        expect(school.reload.stripe_customer_id).to eq("cus_neuf")
      end
    end

    # `update_column` plutôt que `save` : une école dont la ligne est par ailleurs
    # invalide perdait l'id en silence, et un client vide était créé chez Stripe à
    # chaque appel.
    context "quand l'école ne passe plus ses propres validations" do
      before { school.update_column(:email, nil) }

      it "enregistre quand même l'id" do
        described_class.get_or_create_customer(school)
        expect(school.reload.stripe_customer_id).to eq("cus_neuf")
      end
    end
  end
end
