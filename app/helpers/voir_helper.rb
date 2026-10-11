# frozen_string_literal: true

# Les onglets des deux sections de « Voir » : chacune a sa liste, et ses
# exercices — les exercices classiques pour les plans de travail, ceux de
# ceinture pour les ceintures.
module VoirHelper
  def onglets_plans_de_travail(actif)
    [
      { label: "Plans de travail", href: work_plans_path, active: actif == :liste },
      { label: "Exercices", href: challenges_path, active: actif == :exercices }
    ]
  end

  def onglets_ceintures(actif)
    [
      { label: "Ceintures", href: belt_sheets_path, active: actif == :liste },
      { label: "Exercices", href: challenges_path(ceinture: 1), active: actif == :exercices }
    ]
  end
end
