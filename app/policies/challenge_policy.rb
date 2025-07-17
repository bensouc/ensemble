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
    user_is_owner_or_admin?
  end

  def show?
    user_is_owner_or_admin?
  end

  def update?
    user_is_owner_or_admin?
  end

  def edit?
    user_is_owner_or_admin?
  end


  def clone?
    user_is_owner_or_admin?
  end

  def display_challenges?
    user_is_owner_or_admin?
  end

  def destroy?
    user_can_destroy? && challenge_not_used?
  end

  def can_show_delete_button?
    user_can_destroy? && challenge_not_used?
  end

  private

  def user_is_owner_or_admin?
    user.admin || record.skill.school == user.school
  end

  def user_can_destroy?
    record.skill.school == user.school || user.admin? || record.user.admin?
  end

  def challenge_not_used?
    record.work_plan_skills.empty?
  end
end
