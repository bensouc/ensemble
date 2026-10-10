# frozen_string_literal: true

# La grille de progression d'un élève, sur sa fiche : une case par domaine et par
# niveau de ceinture. Tout se charge ici en une poignée de requêtes, puis chaque
# case puise dans ce qui est en mémoire.
#
# Chaque case était un turbo-frame paresseux qui rappelait le serveur : 49
# requêtes HTTP pour 7 domaines, 91 pour 13, chacune repayant session, droits et
# messages non lus — et une dizaine de requêtes SQL par case. Les mises à jour
# d'UNE case (valider, modifier, retirer une ceinture) passent toujours par
# `BeltsController#set_data_show`, qui rend le même partiel.
class GrilleProgression
  def initialize(student, domains)
    @student = student
    skills = Skill.where(domain: domains).to_a
    @skills_par_case = skills.group_by { |skill| [skill.domain_id, skill.level] }
    charger_ceintures
    charger_evaluations(skills)
  end

  # Les locaux de `belts/_belt` pour une case — les mêmes que `set_data_show`.
  # Un domaine « spécial » range toutes ses compétences au niveau 1.
  def case_locals(domain, level)
    skills = @skills_par_case.fetch([domain.id, domain.special? ? 1 : level], [])
    {
      student: @student, domain:, level:,
      belt: @belt_par_case[[domain.id, level]],
      last_belt: @derniere_belt[domain.id],
      skills:,
      results: skills.flat_map { |skill| @results_par_skill.fetch(skill.id, []) },
      last_wps: skills.flat_map { |skill| @last_wps_par_skill.fetch(skill.id, []) }
    }
  end

  private

  def charger_ceintures
    belts = @student.belts.completed.order(:id).to_a
    @belt_par_case = belts.group_by { |belt| [belt.domain_id, belt.level] }.transform_values(&:first)
    @derniere_belt = belts.group_by(&:domain_id).transform_values { |liste| liste.max_by(&:level) }
  end

  def charger_evaluations(skills)
    @results_par_skill = Result.completed.where(student: @student, skill: skills).order(:id).group_by(&:skill_id)
    @last_wps_par_skill = WorkPlanSkill.last_wps(@student, skills).
      includes(work_plan_domain: :work_plan).group_by(&:skill_id)
  end
end
