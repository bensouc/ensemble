# frozen_string_literal: true

module SkillsHelper
  # Les compétences d'une liste, groupées par sous-domaine.
  #
  # Celles qui n'en ont pas viennent en tête, sous une clé `nil` — c'est à la vue
  # de ne pas leur donner de titre. Elles existent, et une boucle sur les seuls
  # sous-domaines trouvés les aurait laissées de côté : le niveau 1 du domaine 52
  # en compte une sur vingt, qu'on n'aurait alors jamais pu valider.
  #
  # Les sous-domaines suivent dans l'ordre alphabétique, et les compétences par
  # nom à l'intérieur de chaque groupe : sans quoi l'ordre dépendrait de celui de
  # la requête, donc changerait d'un chargement à l'autre.
  def competences_par_sous_domaine(skills)
    skills.sort_by(&:name).
      group_by { |skill| skill.sub_domain.presence }.
      sort_by { |sous_domaine, _| [sous_domaine ? 1 : 0, sous_domaine.to_s] }
  end
end
