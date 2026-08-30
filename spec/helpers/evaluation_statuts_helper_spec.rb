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

    # Garde-fou : ce que chaque statut donne à dessiner, sur les deux fronts. Le
    # changer ici le change des deux côtés — ce qui est le but, mais doit rester
    # un geste délibéré.
    #
    # Les trois « à refaire » n'ont plus d'icône : ils portent l'anneau de la
    # pastille, dont la longueur dit combien il reste. C'étaient trois fois la
    # même flèche de rotation que seule la couleur distinguait, en face de
    # pastilles qui, elles, graduent leur arc.
    it "ne garde d'icône que pour les deux états stables" do
      dessins = helper.statuts_evaluation(wps("exercice")).map { |s| [s.icone, s.couleur, s.anneau] }

      expect(dessins).to eq([
                             ["fa-regular fa-circle-xmark", "--grisF", false],
                             [nil, nil, true],
                             [nil, nil, true],
                             [nil, nil, true],
                             ["fa-solid fa-graduation-cap", "text-primary", false],
                           ])
    end

    # La vue choisit entre les deux : un statut sans l'un ni l'autre ne
    # dessinerait rien, et un bouton vide ne se clique pas.
    it "donne à chaque statut un dessin, et un seul" do
      %w[exercice ceinture controle jeu].each do |nature|
        helper.statuts_evaluation(wps(nature)).each do |statut|
          expect(statut.anneau ^ statut.icone.present?).to be(true), "#{nature}/#{statut.statut}"
        end
      end
    end
  end

  # La lettre d'une pastille. Les six vues qui en affichaient une prenaient
  # `kind[0]` : juste, mais par chance, et cela levait dès que la nature
  # manquait — ce qui arrive à un `Result`.
  describe "#lettre_nature" do
    it "donne son initiale à chaque nature" do
      expect(helper.lettre_nature("jeu")).to eq("J")
      expect(helper.lettre_nature("exercice")).to eq("E")
      expect(helper.lettre_nature("ceinture")).to eq("C")
    end

    it "marque un contrôle comme une ceinture" do
      expect(helper.lettre_nature("controle")).to eq(helper.lettre_nature("ceinture"))
    end

    it "ne se laisse pas troubler par la casse" do
      expect(helper.lettre_nature("Exercice")).to eq("E")
    end

    it "se rabat sur l'initiale d'une nature inconnue plutôt que de lever" do
      expect(helper.lettre_nature("atelier")).to eq("A")
    end

    it "rend une pastille muette plutôt que de lever quand la nature manque" do
      expect(helper.lettre_nature(nil)).to eq("")
    end
  end

  # Le contrôle du bureau montre toujours les cinq colonnes, y compris celles
  # qu'une nature n'autorise pas. C'est ce qui permet de balayer une colonne du
  # regard sur tout un plan de travail au lieu de relire chaque ligne : « validé »
  # se trouve toujours au même endroit.
  describe "#cases_evaluation" do
    it "rend toujours cinq cases, dans l'ordre de la progression" do
      cases = helper.cases_evaluation(wps("exercice"))

      expect(cases.size).to eq(5)
      expect(cases.map(&:statut)).to eq(%w[not_done failed redo redo_OK completed])
    end

    it "laisse vides les colonnes qu'une ceinture n'autorise pas, sans décaler les autres" do
      cases = helper.cases_evaluation(wps("ceinture"))

      expect(cases.size).to eq(5)
      expect(cases.map { |c| c&.statut }).to eq(["not_done", nil, "redo", nil, "completed"])
    end

    it "en laisse trois vides pour un jeu" do
      expect(helper.cases_evaluation(wps("jeu")).map { |c| c&.statut })
        .to eq([nil, nil, nil, "redo_OK", "completed"])
    end

    it "n'en remplit aucune pour une nature inconnue plutôt que de lever" do
      expect(helper.cases_evaluation(wps("autre"))).to eq([nil] * 5)
    end

    # Le libellé de validation dépend de ce qu'on évalue : les cases doivent le
    # dire comme le fait la liste des statuts offerts.
    it "dit ce que valider veut dire selon ce qu'on évalue" do
      expect(helper.cases_evaluation(wps("exercice")).last.libelle).to eq("Validé ⇒ ceinture")
      expect(helper.cases_evaluation(wps("ceinture")).last.libelle).to eq("Ceinture validée")
    end
  end

  # `not_done` est le nom du choix ; `new` est ce que la base enregistre. La
  # pastille porte la couleur de l'état, pas celle du chemin qui y mène.
  describe "#classe_pastille" do
    it "traduit le choix « non fait » vers l'état neuf" do
      expect(helper.classe_pastille("not_done")).to eq("new")
    end

    it "laisse les autres statuts tels quels" do
      expect(helper.classe_pastille("redo_OK")).to eq("redo_OK")
      expect(helper.classe_pastille("completed")).to eq("completed")
    end
  end

  # Le mot d'une pastille et celui du choix qui y mène viennent des mêmes tables.
  # La grille de progression en tenait une quatrième copie, qui avait dérivé —
  # « Raté » contre « Raté, à refaire », « A revoir » contre « À refaire » : selon
  # l'écran, l'enseignant lisait deux choses d'un même statut. Ce garde-fou lie
  # les deux plutôt que de recopier les chaînes une fois de plus.
  describe "#libelle_evaluation" do
    it "donne à un statut enregistré le mot du choix qui y mène" do
      choix = helper.statuts_evaluation(wps("exercice")).to_h { |s| [s.statut, s.libelle] }

      expect(helper.libelle_evaluation("new", "exercice")).to eq(choix["not_done"])
      %w[failed redo redo_OK completed].each do |statut|
        expect(helper.libelle_evaluation(statut, "exercice")).to eq(choix[statut]), statut
      end
    end

    it "dit ce que « validé » veut dire selon ce qu'on évalue" do
      expect(helper.libelle_evaluation("completed", "ceinture")).to eq("Ceinture validée")
      expect(helper.libelle_evaluation("completed", "jeu")).to eq("Fait")
    end

    it "se tait plutôt que de lever sur un statut inconnu" do
      expect(helper.libelle_evaluation("autre", "exercice")).to eq("")
    end
  end

  # La légende de la grille de progression. Elle vaut pour toutes les natures à
  # la fois : c'est pourquoi elle emploie le mot générique de validation, là où
  # un exercice dirait « Validé ⇒ ceinture ».
  describe "#legende_evaluation" do
    it "donne les cinq états, du moins avancé au plus avancé" do
      expect(helper.legende_evaluation.map(&:first)).to eq(%w[new failed redo redo_OK completed])
    end

    it "emploie le mot générique de validation" do
      expect(helper.legende_evaluation.last.last).to eq("Validé")
    end

    # Une légende qui répéterait un mot n'expliquerait plus rien.
    it "donne à chaque état un mot, et un mot qui lui est propre" do
      mots = helper.legende_evaluation.map(&:last)

      expect(mots).to all(be_present)
      expect(mots.uniq.size).to eq(mots.size)
    end
  end

  describe "#legende_natures" do
    it "explique les trois lettres" do
      expect(helper.legende_natures).to eq([%w[J Jeu], %w[E Exercice], %w[C Ceinture]])
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
