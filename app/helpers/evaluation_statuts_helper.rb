# frozen_string_literal: true

# Les statuts d'évaluation, leur libellé et leur icône — en un seul endroit.
#
# Ces mots existaient déjà, mais seulement en infobulle sur le bureau, et pas du
# tout sur mobile : la modale n'y montrait que des icônes, dont TROIS flèches de
# rotation identiques que seule la couleur distinguait. Il fallait avoir appris
# le code couleur pour évaluer un élève.
#
# Les rassembler ici sert deux choses : le mobile peut enfin les afficher, et
# les deux fronts ne peuvent plus dériver l'un de l'autre.
module EvaluationStatutsHelper
  Statut = Struct.new(:statut, :libelle, :icone, :couleur, :anneau, keyword_init: true)

  # Ordonnés du moins avancé au plus avancé : la liste se lit comme une
  # progression, pas comme un menu.
  LIBELLES = {
    "not_done" => "Non fait",
    "failed" => "Raté, à refaire",
    "redo" => "À refaire",
    "redo_OK" => "OK, mais à refaire"
  }.freeze

  # Les trois statuts qui veulent dire « il faut y revenir ». Le sélecteur leur
  # donnait trois fois la même flèche de rotation, que seule la couleur
  # distinguait — le défaut même que la pastille vient de corriger en graduant
  # son anneau. Ils reçoivent maintenant cet anneau : le bouton montre l'arc que
  # la pastille prendra si on le choisit.
  A_REFAIRE = %w[failed redo redo_OK].freeze

  # Ne restent en icône que les deux états stables : rien à refaire d'un côté,
  # rien de plus à faire de l'autre.
  ICONES = {
    "not_done" => ["fa-regular fa-circle-xmark", "--grisF"]
  }.freeze

  # La lettre d'une pastille. Les six vues qui en affichaient une prenaient
  # `kind[0]` : « jeu » donnait J, « exercice » E, « ceinture » et « controle »
  # C — juste, mais par chance. Une nature dont le nom aurait commencé par la
  # même lettre qu'une autre aurait changé le dessin toute seule.
  LETTRES = {
    "jeu" => "J",
    "exercice" => "E",
    "ceinture" => "C",
    "controle" => "C"
  }.freeze

  # `completed` ne veut pas dire la même chose selon ce qu'on évalue : un
  # exercice validé donne la ceinture, une ceinture est validée, un jeu est
  # simplement fait.
  VALIDATION = {
    "exercice" => ["Validé ⇒ ceinture", "fa-solid fa-graduation-cap"],
    "ceinture" => ["Ceinture validée", "fa-solid fa-graduation-cap"],
    "controle" => ["Ceinture validée", "fa-solid fa-graduation-cap"],
    "jeu" => ["Fait", "fas fa-pen"]
  }.freeze

  STATUTS_PAR_NATURE = {
    "exercice" => %w[not_done failed redo redo_OK completed],
    "ceinture" => %w[not_done redo completed],
    "controle" => %w[not_done redo completed],
    "jeu" => %w[redo_OK completed]
  }.freeze

  # Les cinq états, dans l'ordre de la progression. `statuts_evaluation` ne
  # rend que ceux qu'une nature autorise — deux pour un jeu, trois pour une
  # ceinture ; le contrôle du bureau, lui, montre toujours les cinq colonnes et
  # laisse vides celles qui ne s'appliquent pas. C'est ce qui permet de balayer
  # une colonne du regard sur tout un plan de travail, au lieu de relire chaque
  # ligne pour retrouver où se trouve « validé ».
  ORDRE = %w[not_done failed redo redo_OK completed].freeze

  def cases_evaluation(plan_skill)
    nature = plan_skill.kind.to_s.downcase
    offerts = STATUTS_PAR_NATURE.fetch(nature, [])
    ORDRE.map { |statut| construire_statut(statut, nature) if offerts.include?(statut) }
  end

  # `not_done` est enregistré `new` en base : la pastille porte donc la classe
  # de l'état enregistré, pas celle du choix qui y mène.
  def classe_pastille(statut)
    statut == "not_done" ? "new" : statut
  end

  # Le mot qui dit un statut déjà enregistré — l'infobulle d'une pastille. Le
  # sélecteur, lui, prend le libellé de son propre `Statut` : c'est le même
  # texte, tiré des mêmes tables, mais une pastille n'a pas de `Statut` sous la
  # main. La correspondance `new` → `not_done` se refait donc en sens inverse,
  # faute de quoi une compétence remise à zéro n'aurait pas d'infobulle du tout.
  def libelle_evaluation(statut, kind)
    statut = statut.to_s == "new" ? "not_done" : statut.to_s
    return VALIDATION.fetch(kind.to_s.downcase, ["Validé"]).first if statut == "completed"

    LIBELLES.fetch(statut, "")
  end

  # La légende de la grille de progression : les cinq états, du moins avancé au
  # plus avancé, avec le mot de chacun.
  #
  # Sans nature, `libelle_evaluation` rend le mot générique — « Validé », là où
  # un exercice dirait « Validé ⇒ ceinture ». C'est ce que veut une légende, qui
  # parle de toutes les natures à la fois.
  def legende_evaluation
    ORDRE.map { |statut| [classe_pastille(statut), libelle_evaluation(classe_pastille(statut), nil)] }
  end

  # Ce que dit la lettre d'une pastille. « Contrôle » partage le C de
  # « ceinture » : la légende ne le répète pas, les deux disent la même chose à
  # l'élève. Les lettres viennent de `lettre_nature`, pas d'une copie.
  def legende_natures
    %w[jeu exercice ceinture].map { |nature| [lettre_nature(nature), nature.capitalize] }
  end

  def lettre_nature(kind)
    nature = kind.to_s.downcase
    LETTRES.fetch(nature) { nature[0].to_s.upcase }
  end

  def statuts_evaluation(plan_skill)
    nature = plan_skill.kind.to_s.downcase
    STATUTS_PAR_NATURE.fetch(nature, []).map { |statut| construire_statut(statut, nature) }
  end

  # Le statut affiché aujourd'hui. `not_done` est enregistré `new` en base : sans
  # cette correspondance, une compétence remise à zéro n'aurait aucun choix
  # marqué comme courant.
  def statut_courant?(plan_skill, statut)
    return plan_skill.status == "new" if statut == "not_done"

    plan_skill.status == statut
  end

  private

  def construire_statut(statut, nature)
    if statut == "completed"
      libelle, icone = VALIDATION.fetch(nature, ["Validé", "fa-solid fa-graduation-cap"])
      return Statut.new(statut:, libelle:, icone:, couleur: "text-primary", anneau: false)
    end

    return Statut.new(statut:, libelle: LIBELLES.fetch(statut), anneau: true) if A_REFAIRE.include?(statut)

    icone, couleur = ICONES.fetch(statut)
    Statut.new(statut:, libelle: LIBELLES.fetch(statut), icone:, couleur:, anneau: false)
  end
end
