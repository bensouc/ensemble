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

  # Les compétences qu'on peut ajouter à un domaine d'un plan de travail, dans
  # l'ordre que l'enseignant a rangé — la liste suivait l'ordre des symboles.
  #
  # Celles que l'élève a déjà validées en ceinture passent dans un second groupe,
  # marquées d'une coche : une liste déroulante native n'affiche ni icône ni fond
  # coloré sur macOS, un groupe et une coche si. Elles restent sélectionnables —
  # on peut vouloir retravailler une compétence acquise.
  def options_competences_a_ajouter(work_plan_domain)
    skills = Skill.where(domain_id: work_plan_domain.domain_id, level: work_plan_domain.level).order(:position, :id)
    validees = competences_validees_en_ceinture(work_plan_domain, skills)
    a_travailler, deja_validees = skills.partition { |skill| validees.exclude?(skill.id) }
    return options_for_select(a_travailler.map { |skill| [skill.name, skill.id] }) if deja_validees.empty?

    grouped_options_for_select(
      "À travailler" => a_travailler.map { |skill| [skill.name, skill.id] },
      "Déjà validées en ceinture" => options_validees(deja_validees)
    )
  end

  private

  def options_validees(skills)
    skills.map { |skill| ["✓ #{skill.name}", skill.id, { class: "competence-validee" }] }
  end

  def competences_validees_en_ceinture(work_plan_domain, skills)
    Result.completed.where(student_id: work_plan_domain.work_plan.student_id, skill: skills).pluck(:skill_id).to_set
  end
end
