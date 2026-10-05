# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::Practice do
  let(:competence) { create(:manipule_skill) }
  let(:eleve) { create(:student) }

  # Les traits de FactoryBot sont positionnels : `banque(5, :brouillon)`.
  def banque(nombre, *traits, **attributs)
    create_list(:manipule_problem, nombre, *traits, skill: competence, **attributs)
  end

  describe ".commencer!" do
    it "crée une tentative par problème tiré, dans l'ordre" do
      banque(3)

      serie = described_class.commencer!(student: eleve, skill: competence)

      expect(serie.attempts.count).to eq(3)
      expect(serie.attempts.map(&:position)).to eq([1, 2, 3])
      expect(serie.size).to eq(3)
    end

    it "ne tire pas plus que la taille demandée" do
      banque(12)

      serie = described_class.commencer!(student: eleve, skill: competence, size: 4)

      expect(serie.attempts.count).to eq(4)
    end

    it "laisse les tentatives en attente : une série abandonnée doit se voir" do
      banque(2)

      serie = described_class.commencer!(student: eleve, skill: competence)

      expect(serie.attempts.map(&:status).uniq).to eq(["pending"])
      expect(serie.attempts.repondues).to be_empty
    end

    it "ignore les problèmes qui ne sont pas visible" do
      banque(2)
      banque(5, :brouillon)

      serie = described_class.commencer!(student: eleve, skill: competence)

      expect(serie.attempts.count).to eq(2)
    end

    it "refuse de commencer quand la banque est vide" do
      banque(3, :brouillon)

      expect { described_class.commencer!(student: eleve, skill: competence) }.
        to raise_error(ArgumentError, /Aucun problème visible/)
    end

    it "ne laisse pas de série orpheline quand la création échoue" do
      banque(2)
      allow_any_instance_of(described_class).to receive(:attempts).and_raise(ActiveRecord::RecordInvalid)

      expect { described_class.commencer!(student: eleve, skill: competence) }.to raise_error(StandardError)
      expect(described_class.count).to eq(0)
    end
  end

  describe "la fin de la série" do
    it "n'est terminée qu'une fois terminée, et sa durée n'existe pas avant" do
      banque(1)
      serie = described_class.commencer!(student: eleve, skill: competence)

      expect(serie).not_to be_terminee
      expect(serie.duree).to be_nil

      serie.terminer!

      expect(serie).to be_terminee
      expect(serie.duree).to be >= 0
    end
  end
end
