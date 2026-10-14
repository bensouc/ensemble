# frozen_string_literal: true

# Les onglets des deux sections de « Voir » : chacune a sa liste, et ses
# exercices — les exercices classiques pour les plans de travail, ceux de
# ceinture pour les ceintures. Les libellés des ceintures le disent : les deux
# pages se ressemblent trait pour trait, et « Exercices » des deux côtés
# laissait croire à une même liste.
module VoirHelper
  # La section de « Voir » où l'on se trouve : le sous-menu de la barre de gauche
  # reste ouvert tant qu'on y est, et son entrée y est marquée. `nil` hors de
  # « Voir ».
  def section_voir
    case controller_name
    when "work_plans" then :plans if action_name == "index"
    when "challenges" then exercices_de_ceinture? ? :ceintures : :plans
    when "belt_sheets", "belt_sheet_domains", "belt_sheet_skills" then :ceintures
    when "skills" then :progressions
    end
  end

  def exercices_de_ceinture?
    params[:ceinture].present? && fiches_de_ceinture_ouvertes?
  end

  def onglets_plans_de_travail(actif)
    [
      { label: "Plans de travail", href: work_plans_path, active: actif == :liste },
      { label: "Exercices", href: challenges_path, active: actif == :exercices }
    ]
  end

  def onglets_ceintures(actif)
    [
      { label: "Fiches de ceinture", href: belt_sheets_path, active: actif == :liste },
      { label: "Exercices de ceinture", href: challenges_path(ceinture: 1), active: actif == :exercices }
    ]
  end

  # Le second niveau d'onglets des fiches de ceinture : celles des élèves, et
  # celles d'aucun élève, générées depuis les exercices de ceinture.
  def onglets_fiches_de_ceinture(actif)
    [
      { label: "Par élève", href: belt_sheets_path, active: actif == :par_eleve },
      { label: "Non assignées", href: non_assignees_belt_sheets_path, active: actif == :non_assignees }
    ]
  end
end
