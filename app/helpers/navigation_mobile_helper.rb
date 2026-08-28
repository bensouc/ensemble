# frozen_string_literal: true

# La barre de navigation du bas.
module NavigationMobileHelper
  # L'onglet courant. `current_page?` ne convient pas : il exige l'URL exacte,
  # alors qu'une fiche élève ou l'évaluation d'un plan doivent garder allumé
  # l'onglet dont elles dépendent.
  def onglet_mobile_actif?(chemin)
    return request.path == "/" if chemin == "/"

    request.path.start_with?(chemin)
  end

  def classe_onglet_mobile(chemin)
    "mobile-user-menu#{' --actif' if onglet_mobile_actif?(chemin)}"
  end
end
