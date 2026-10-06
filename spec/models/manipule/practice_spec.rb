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

  # Avant, le tirage était `ORDER BY RANDOM()` : l'ordre donné par
  # l'enseignante ne servait à rien, et l'élève pouvait retomber le lendemain
  # sur les mêmes problèmes alors qu'il en restait des neufs.
  describe "le choix des problèmes" do
    # Une séance passée, réduite à ce qui compte : un problème, un statut, une
    # date. La série n'a pas besoin d'être terminée.
    def deja_fait(probleme, statut, quand)
      serie = described_class.create!(student: eleve, skill: competence, started_at: quand, size: 1)
      serie.attempts.create!(problem: probleme, position: 1, status: statut, answered_at: quand)
    end

    it "sert d'abord ce qu'il n'a jamais vu, dans l'ordre de l'enseignante" do
      problemes = banque(3)
      problemes.each_with_index { |probleme, rang| probleme.update!(position: 3 - rang) }

      serie = described_class.commencer!(student: eleve, skill: competence, size: 3)

      expect(serie.attempts.map(&:problem)).to eq(problemes.reverse)
    end

    it "revient sur ce qui a été raté avant ce qui a été réussi" do
      rate, reussi, jamais_vu = banque(3)
      deja_fait(rate, "wrong", 2.days.ago)
      deja_fait(reussi, "correct", 3.days.ago)

      serie = described_class.commencer!(student: eleve, skill: competence, size: 3)

      expect(serie.attempts.map(&:problem)).to eq([jamais_vu, rate, reussi])
    end

    it "traite un problème passé comme un problème raté : il revient" do
      passe, reussi = banque(2)
      deja_fait(passe, "skipped", 1.day.ago)
      deja_fait(reussi, "correct", 1.day.ago)

      serie = described_class.commencer!(student: eleve, skill: competence, size: 1)

      expect(serie.attempts.first.problem).to eq(passe)
    end

    it "ne resert pas les mêmes tant qu'il reste du neuf" do
      banque(6)
      premiere = described_class.commencer!(student: eleve, skill: competence, size: 3)
      premiere.attempts.each { |tentative| tentative.update!(status: "correct", answered_at: Time.current) }

      seconde = described_class.commencer!(student: eleve, skill: competence, size: 3)

      expect(seconde.attempts.map(&:problem_id)).not_to include(*premiere.attempts.map(&:problem_id))
    end

    # Un problème affiché puis abandonné n'a rien appris à personne.
    it "ne compte pas comme vu un problème resté sans réponse" do
      abandonne, = banque(2)
      abandonnee = described_class.create!(student: eleve, skill: competence, started_at: 1.day.ago, size: 1)
      abandonnee.attempts.create!(problem: abandonne, position: 1)

      serie = described_class.commencer!(student: eleve, skill: competence, size: 1)

      expect(serie.attempts.first.problem).to eq(abandonne)
    end

    it "ne regarde que l'histoire de CET élève" do
      vu_par_un_autre, jamais_vu = banque(2)
      autre = create(:student)
      serie_voisine = described_class.create!(student: autre, skill: competence, started_at: 1.day.ago, size: 1)
      serie_voisine.attempts.create!(problem: vu_par_un_autre, position: 1, status: "correct",
                                     answered_at: 1.day.ago)

      serie = described_class.commencer!(student: eleve, skill: competence, size: 2)

      expect(serie.attempts.map(&:problem)).to eq([vu_par_un_autre, jamais_vu])
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
