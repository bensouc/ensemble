# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subscription do
  def abonnement(attrs = {})
    described_class.new({ status: "active", rythm: "Annuel", quantity: 3,
                          current_period_start: Date.new(2026, 9, 1),
                          current_period_end: Date.new(2027, 8, 31) }.merge(attrs))
  end

  # Le portail client de Stripe ne sait pas modifier un abonnement sur facture :
  # le client peut l'y annuler, consulter et régler ses factures, mais ni changer
  # sa quantité ni changer d'offre. Payer la facture n'y change rien — c'est le
  # `collection_method` qui décide.
  describe "#sur_facture?" do
    it "reconnaît un abonnement facturé" do
      expect(abonnement(collection_method: "send_invoice")).to be_sur_facture
    end

    it "ne prend pas un prélèvement automatique pour une facture" do
      expect(abonnement(collection_method: "charge_automatically")).not_to be_sur_facture
    end

    # Les lignes antérieures à la colonne : nul se comporte comme avant, le
    # portail reste proposé. `stripe:backfill_collection_method` les renseigne.
    it "laisse le portail aux lignes anciennes, sans mode connu" do
      expect(abonnement(collection_method: nil)).not_to be_sur_facture
      expect(abonnement(collection_method: nil)).to be_modifiable_par_lecole
    end
  end

  # Mêmes règles que `calculate_subscription_controller.js`, dont le commentaire
  # dit le piège : seul l'INDICE du barème se plafonne, la quantité réelle reste
  # le multiplicateur. La branche mensuelle du JS annonçait 45 € pour 12 classes
  # là où Stripe en facture 60.
  describe ".cout_annonce" do
    it "suit les paliers annuels" do
      expect(described_class.cout_annonce("Annuel", 2)).to eq(100)
      expect(described_class.cout_annonce("Annuel", 8)).to eq(376)
      expect(described_class.cout_annonce("Annuel", 9)).to eq(414)
    end

    # Le tableau s'arrête à l'indice 9 : au-delà le tarif unitaire ne bouge plus,
    # mais le total continue de monter.
    it "plafonne l'indice, pas le total" do
      expect(described_class.cout_annonce("Annuel", 12)).to eq(46 * 12)
    end

    it "compte le mensuel à la classe" do
      expect(described_class.cout_annonce("Mensuel", 12)).to eq(60)
    end

    # Une quantité nulle ou absente ne doit pas indexer le tableau par la fin.
    it "ne va pas chercher la fin du tableau sur une quantité vide" do
      expect(described_class.cout_annonce("Annuel", nil)).to eq(0)
      expect(described_class.cout_annonce("Annuel", -3)).to eq(0)
    end
  end
end
