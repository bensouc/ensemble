# frozen_string_literal: true

module SkillsHelper
  # Les compétences d'une liste, groupées par sous-domaine.
  #
  # `.sort` et non `sort_by(&:name)` : les compétences portent une `position`,
  # que l'enseignant range, et `Positionable` la donne à `<=>`. Trier par nom
  # défaisait ce rangement — au niveau 1 du domaine 52, les sous-domaines sont
  # des blocs contigus dans l'ordre voulu (1-6 « Les instruments », 7-12 « Les
  # figures géométriques »…), et l'alphabet les ressortait à l'envers.
  #
  # Les groupes suivent donc la position de leur première compétence, ce qui
  # rend leur ordre à la séquence pédagogique. Seul le groupe sans sous-domaine
  # passe devant : ses étiquettes n'ont pas de titre, et posées entre deux
  # groupes titrés elles sembleraient appartenir à celui du dessus.
  #
  # Celles qui n'ont pas de sous-domaine viennent sous une clé `nil` — elles
  # existent, et une boucle sur les seuls sous-domaines trouvés les aurait
  # laissées de côté : le niveau 1 du domaine 52 en compte une sur vingt-et-une,
  # qu'on n'aurait alors jamais pu valider.
  def competences_par_sous_domaine(skills)
    skills.sort.
      group_by { |skill| skill.sub_domain.presence }.
      sort_by { |sous_domaine, competences| [sous_domaine ? 1 : 0, competences.first.position.to_i] }
  end
end
