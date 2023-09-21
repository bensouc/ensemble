class ChallengePolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.includes([:skill, :rich_text_content]).where(user: user) # Only show challenges that belong to the current user ?? Maybe the whole schhol/group
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

  private

  def user_is_owner_or_admin?
    user.admin || record.skill.school == user.school
  end
end
