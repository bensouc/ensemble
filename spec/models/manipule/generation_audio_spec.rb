# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::GenerationAudio do
  let(:probleme) { create(:manipule_problem, skill: create(:manipule_skill)) }

  before do
    rendu = Manipule::Synthese::Rendu.new(octets: "x", content_type: "audio/mp4",
                                          voix: Manipule::Synthese.voix_defaut)
    allow_any_instance_of(Manipule::Synthese).to receive(:generer).and_return(rendu)
  end

  # Les caractères sont l'unité de facturation des voix neuronales : c'est la
  # seule mesure qui dise ce qu'une exécution vient de coûter.
  it "compte les caractères réellement envoyés à la synthèse" do
    generation = described_class.new.traiter_probleme(probleme)

    attendu = probleme.statement.length + probleme.question.length +
              probleme.choices.sum { |choix| choix.label.length }
    expect(generation.caracteres).to eq(attendu)
    expect(generation.faits).to eq(5)
  end

  it "ne compte pas ce qu'il n'a pas eu à refaire" do
    described_class.new.traiter_probleme(probleme)
    generation = described_class.new.traiter_probleme(probleme.reload)

    expect(generation.caracteres).to eq(0)
    expect(generation.sautes).to eq(5)
  end

  describe "le résumé d'une exécution" do
    it "situe la consommation dans l'allocation du fournisseur" do
      allow_any_instance_of(Manipule::Synthese).to receive(:allocation_mensuelle).and_return(500_000)
      generation = described_class.new.traiter_probleme(probleme)

      expect(generation.resume.join(" ")).to match(/caractères consommés, soit 0\.0\d % de l'allocation/)
    end

    # La voix du système ne consomme rien : annoncer un pourcentage de rien
    # ferait croire à un compteur qui tourne.
    it "ne raconte pas de pourcentage quand il n'y a rien à consommer" do
      allow_any_instance_of(Manipule::Synthese).to receive(:allocation_mensuelle).and_return(nil)
      generation = described_class.new.traiter_probleme(probleme)

      expect(generation.resume.join(" ")).to include("caractères consommés.")
      expect(generation.resume.join(" ")).not_to include("allocation")
    end
  end

  describe "le plafond par exécution" do
    # Pas pour rationner : pour arrêter une boucle qui s'emballe avant qu'elle
    # ne consomme l'allocation du mois.
    it "s'arrête net plutôt que de continuer à consommer" do
      generation = described_class.new(plafond: 1)

      expect { generation.traiter_probleme(probleme) }
        .to raise_error(Manipule::Synthese::Quota, /Plafond de 1 caractères/)
    end

    it "compte avant de parler, pour ne pas dépasser d'un morceau" do
      generation = described_class.new(plafond: 1)

      expect { generation.traiter_probleme(probleme) }.to raise_error(Manipule::Synthese::Quota)
      expect(Manipule::Audio.count).to eq(0)
    end

    # Le job ne relance pas un `Indisponible`, et `Quota` en hérite : une
    # banque trop grosse n'encombre pas les jobs en échec.
    it "lève une erreur que le job jette au lieu de la relancer" do
      expect(Manipule::Synthese::Quota.ancestors).to include(Manipule::Synthese::Indisponible)
    end
  end
end
