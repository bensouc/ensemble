class ChallengePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # scope.includes([:skill, :rich_text_content]).same_school(user).all
      # school = user.school
      # skills = school.skills
      # binding.pry
      # scope.includes([:skill, :rich_text_content]).where(skills: skills)
      scope.includes([:skill, :rich_text_content,
                      :work_plan_skills]).joins(:skill).where(skills: { school: user.school })
    end
  end

  def create?
    same_school_or_admin?
  end

  def show?
    same_school_or_admin?
  end

  def update?
    same_school_or_admin?
  end

  def edit?
    same_school_or_admin?
  end

  def clone?
    same_school_or_admin?
  end

  def display_challenges?
    same_school_or_admin?
  end

  def move?
    same_school_or_admin?
  end

  def destroy?
    user_can_destroy? && challenge_not_used?
  end

  def can_show_delete_button?
    user_can_destroy? && challenge_not_used?
  end

  # Déplacer un exercice sous une autre compétence n'est possible que tant qu'il
  # ne sert à personne : dès qu'un plan de travail s'y réfère, le changer de
  # compétence réécrirait l'historique d'un élève. Même garde-fou que la
  # suppression, `challenge_not_used?`.
  def transferable?
    same_school_or_admin? && challenge_not_used?
  end

  private

  # Le nom précédent, `same_school_or_admin?`, décrivait une règle que cette
  # méthode n'applique pas : elle ne regarde pas qui a écrit l'exercice, mais
  # l'école de sa compétence. TOUS les enseignants d'une école travaillent sur
  # ses exercices — c'est le principe, et le nom le disait de travers.
  def same_school_or_admin?
    user.admin || record.skill.school == user.school
  end

  # `record.user&.admin?` : un exercice dont l'auteur a quitté l'école n'a plus
  # d'auteur, et `record.user.admin?` levait alors un NoMethodError. Le
  # rattachement qui compte est `record.skill.school`, juste au-dessus.
  def user_can_destroy?
    record.skill.school == user.school || user.admin? || record.user&.admin?
  end

  def challenge_not_used?
    record.work_plan_skills.empty?
  end
end
