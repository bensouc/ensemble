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
  Statut = Struct.new(:statut, :libelle, :icone, :couleur, keyword_init: true)

  # Ordonnés du moins avancé au plus avancé : la liste se lit comme une
  # progression, pas comme un menu.
  LIBELLES = {
    "not_done" => "Non fait",
    "failed" => "Raté, à refaire",
    "redo" => "À refaire",
    "redo_OK" => "OK, mais à refaire"
  }.freeze

  ICONES = {
    "not_done" => ["fa-regular fa-circle-xmark", "--grisF"],
    "failed" => ["fa-solid fa-arrow-rotate-left", "text-danger"],
    "redo" => ["fa-solid fa-arrow-rotate-left", "orange"],
    "redo_OK" => ["fa-solid fa-arrow-rotate-left", "text-success"]
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
      return Statut.new(statut:, libelle:, icone:, couleur: "text-primary")
    end

    icone, couleur = ICONES.fetch(statut)
    Statut.new(statut:, libelle: LIBELLES.fetch(statut), icone:, couleur:)
  end
end
