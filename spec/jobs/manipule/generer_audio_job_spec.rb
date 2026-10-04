# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::GenererAudioJob do
  include ActiveJob::TestHelper

  let(:competence) { create(:manipule_skill) }

  describe "ce qui poste le job" do
    it "la mise en circulation d'un problème" do
      probleme = create(:manipule_problem, :brouillon, skill: competence)

      expect { probleme.update!(published: true) }.
        to have_enqueued_job(described_class).with(probleme)
    end

    it "la correction d'un énoncé déjà en circulation" do
      probleme = create(:manipule_problem, skill: competence)

      expect { probleme.update!(statement: "Il y a 12 pommes sur le pommier.") }.
        to have_enqueued_job(described_class).with(probleme)
    end

    it "la correction d'une réponse déjà en circulation" do
      probleme = create(:manipule_problem, skill: competence)

      expect { probleme.choices.first.update!(label: "9 pommes") }.
        to have_enqueued_job(described_class).with(probleme)
    end
  end

  describe "ce qui ne le poste pas" do
    # Un brouillon ne coûte rien à personne : nul ne l'écoute.
    it "la création d'un brouillon" do
      expect { create(:manipule_problem, :brouillon, skill: competence) }.
        not_to have_enqueued_job(described_class)
    end

    it "la modification d'un brouillon" do
      probleme = create(:manipule_problem, :brouillon, skill: competence)

      expect { probleme.update!(statement: "Autre chose.") }.
        not_to have_enqueued_job(described_class)
    end

    it "le retrait de la circulation" do
      probleme = create(:manipule_problem, skill: competence)

      expect { probleme.update!(published: false) }.
        not_to have_enqueued_job(described_class)
    end

    # Changer la position d'un problème ne change pas ce qu'on entend.
    it "une modification qui ne touche à aucun texte" do
      probleme = create(:manipule_problem, skill: competence)

      expect { probleme.update!(position: 3) }.
        not_to have_enqueued_job(described_class)
    end
  end

  describe "l'exécution" do
    let(:probleme) { create(:manipule_problem, skill: competence) }

    it "ne refait que les parties dont le texte a changé" do
      allow(Manipule::Synthese).to receive(:disponible?).and_return(true)
      rendu = Manipule::Synthese::Rendu.new(octets: "x", content_type: "audio/mp4",
                                            voix: Manipule::Synthese.voix_defaut)
      allow_any_instance_of(Manipule::Synthese).to receive(:generer).and_return(rendu)

      described_class.perform_now(probleme)
      expect(Manipule::Audio.count).to eq(5)

      # Rien n'a bougé : aucune synthèse supplémentaire.
      expect_any_instance_of(Manipule::Synthese).not_to receive(:generer)
      described_class.perform_now(probleme)
    end

    it "ne fait rien pour un problème retiré de la circulation entre-temps" do
      probleme.update_column(:published, false)

      expect(Manipule::Synthese).not_to receive(:disponible?)
      described_class.perform_now(probleme)
    end

    # Le serveur de production n'a pas `say` : inutile d'encombrer les jobs en
    # échec avec quelque chose qui ne peut pas aboutir.
    it "abandonne sans bruit là où la synthèse n'existe pas" do
      allow(Manipule::Synthese).to receive(:disponible?).and_return(false)

      expect { described_class.perform_now(probleme) }.not_to raise_error
      expect(Manipule::Audio.count).to eq(0)
    end
  end
end
