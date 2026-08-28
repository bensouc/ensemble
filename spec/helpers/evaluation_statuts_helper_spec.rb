# frozen_string_literal: true

require "rails_helper"

# Ce helper est la source unique des deux fronts : le bureau y prend ses
# infobulles, la modale du mobile ses libellés. Une dérive ici se voit partout.
RSpec.describe EvaluationStatutsHelper, type: :helper do
  def wps(kind, status = "new")
    WorkPlanSkill.new(kind:, status:)
  end

  describe "#statuts_evaluation" do
    it "propose les cinq statuts d'un exercice, du moins avancé au plus avancé" do
      expect(helper.statuts_evaluation(wps("exercice")).map(&:statut))
        .to eq(%w[not_done failed redo redo_OK completed])
    end

    it "n'en propose que trois pour une ceinture" do
      expect(helper.statuts_evaluation(wps("ceinture")).map(&:statut))
        .to eq(%w[not_done redo completed])
    end

    it "traite un contrôle comme une ceinture" do
      expect(helper.statuts_evaluation(wps("controle")).map(&:statut))
        .to eq(helper.statuts_evaluation(wps("ceinture")).map(&:statut))
    end

    it "n'en propose que deux pour un jeu" do
      expect(helper.statuts_evaluation(wps("jeu")).map(&:statut)).to eq(%w[redo_OK completed])
    end

    it "ne propose rien pour une nature inconnue plutôt que de lever" do
      expect(helper.statuts_evaluation(wps("autre"))).to be_empty
    end

    # Trois des cinq icônes sont la même flèche de rotation : c'est le libellé,
    # et lui seul, qui distingue les statuts. Deux libellés identiques
    # rendraient la modale à nouveau indéchiffrable.
    it "donne à chaque statut un libellé qui lui est propre" do
      libelles = helper.statuts_evaluation(wps("exercice")).map(&:libelle)

      expect(libelles.uniq.size).to eq(libelles.size)
      expect(libelles).to all(be_present)
    end

    it "dit ce que valider veut dire selon ce qu'on évalue" do
      validation = ->(kind) { helper.statuts_evaluation(wps(kind)).last.libelle }

      expect(validation.call("exercice")).to eq("Validé ⇒ ceinture")
      expect(validation.call("ceinture")).to eq("Ceinture validée")
      expect(validation.call("jeu")).to eq("Fait")
    end

    # Garde-fou : ces icônes sont celles que les deux fronts affichaient déjà.
    # Les changer ici les change des deux côtés — ce qui est le but, mais doit
    # rester un geste délibéré.
    it "conserve les icônes des deux fronts" do
      icones = helper.statuts_evaluation(wps("exercice")).map { |s| [s.icone, s.couleur] }

      expect(icones).to eq([
                             ["fa-regular fa-circle-xmark", "--grisF"],
                             ["fa-solid fa-arrow-rotate-left", "text-danger"],
                             ["fa-solid fa-arrow-rotate-left", "orange"],
                             ["fa-solid fa-arrow-rotate-left", "text-success"],
                             ["fa-solid fa-graduation-cap", "text-primary"],
                           ])
    end
  end

  describe "#statut_courant?" do
    it "reconnaît le statut enregistré" do
      expect(helper.statut_courant?(wps("exercice", "redo"), "redo")).to be true
    end

    it "n'en reconnaît qu'un" do
      expect(helper.statut_courant?(wps("exercice", "redo"), "completed")).to be false
    end

    # `not_done` est enregistré `new` en base : sans cette correspondance, une
    # compétence remise à zéro n'aurait aucun choix marqué dans la modale.
    it "fait correspondre « non fait » à l'état neuf enregistré en base" do
      expect(helper.statut_courant?(wps("exercice", "new"), "not_done")).to be true
    end
  end
end
