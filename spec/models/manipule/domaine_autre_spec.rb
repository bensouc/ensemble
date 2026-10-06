# frozen_string_literal: true

require "rails_helper"

# « Autre » est un vrai domaine, avec son niveau et ses ceintures — c'est
# précisément ce qu'on veut en réutiliser. Mais il ne doit exister que pour
# Manipule : ni dans la progression d'un élève, ni dans la grille de ceintures,
# ni dans la génération des plans de travail.
RSpec.describe Manipule::DomaineAutre do
  let(:ecole) { create(:school) }
  let(:niveau) { create(:grade, school: ecole, name: "CE1", grade_level: "CE1") }
  let!(:domaine_ensemble) { create(:domain, grade: niveau, name: "Calcul") }
  let!(:competence_ensemble) { create(:skill, domain: domaine_ensemble, school: ecole, level: 1) }

  describe "le domaine lui-même" do
    it "se crée à la première compétence, et une seule fois par niveau" do
      described_class.ajouter_competence!(niveau:, nom: "Le nombre du jour", ceinture: 1)
      described_class.ajouter_competence!(niveau:, nom: "Les doubles", ceinture: 2)

      expect(Domain.where(grade: niveau, manipule: true).count).to eq(1)
      expect(described_class.pour(niveau).name).to eq("Autre")
    end

    it "n'existe pas tant qu'on n'y a rien rangé" do
      expect(described_class.pour(niveau)).to be_nil
    end

    # Le `school_id` d'une compétence et celui du niveau de son domaine peuvent
    # diverger : c'est de là que venait la fuite entre écoles.
    it "range la compétence dans l'école du NIVEAU" do
      competence = described_class.ajouter_competence!(niveau:, nom: "Le nombre du jour", ceinture: 3)

      expect(competence.school).to eq(ecole)
      expect(competence.domain.grade.school).to eq(ecole)
      expect(competence.level).to eq(3)
    end
  end

  describe "ce qu'Ensemble en voit" do
    before { described_class.ajouter_competence!(niveau:, nom: "Le nombre du jour", ceinture: 1) }

    it "rien : ni le domaine, ni ses compétences" do
      expect(niveau.domains).to eq([domaine_ensemble])
      expect(niveau.skills).to eq([competence_ensemble])
    end

    it "pas davantage dans la progression d'un élève" do
      eleve = create(:student, classroom: create(:classroom, user: create(:user), grade: niveau))

      expect(eleve.domains.map(&:name)).to eq(["Calcul"])
    end

    it "mais `domaines_manipule` les voit : c'est par là que Manipule passe" do
      expect(niveau.domaines_manipule.map(&:name)).to eq(["Autre"])
    end
  end

  # La clef étrangère `domains → grades` n'a pas d'`on_delete`. `Grade` porte
  # donc deux associations complémentaires, chacune avec `dependent: :destroy` :
  # si une seule des deux l'avait, le domaine de l'autre serait resté derrière
  # et la base aurait refusé de supprimer le niveau. C'est très exactement le
  # piège déjà rencontré sur les tables de Manipule.
  it "ne bloque pas la suppression de son niveau" do
    described_class.ajouter_competence!(niveau:, nom: "Le nombre du jour", ceinture: 1)

    expect { niveau.destroy! }.not_to raise_error
    expect(Domain.where(grade_id: niveau.id)).to be_empty
  end

  describe "ce que Manipule en voit" do
    it "le domaine et ses compétences, comme n'importe quel autre" do
      competence = described_class.ajouter_competence!(niveau:, nom: "Le nombre du jour", ceinture: 1)
      recherche = Manipule::Recherche.new(ecole:, niveaux: Grade.where(id: niveau.id),
                                          deja_ecrites: [], filtres: { niveau: niveau.id })

      expect(recherche.domaines.flat_map(&:last).map(&:first)).to include("Autre")
      expect(recherche.competences).to include(competence)
    end
  end
end
