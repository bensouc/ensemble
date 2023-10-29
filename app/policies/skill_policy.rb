class SkillPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.includes([:challenges, :grade, :school]).where(school: user.school)
    end
  end

  def show?
    user_is_owner_or_admin?
  end

  def edit?
    user_is_owner_or_admin?
  end

  def update?
    user_is_owner_or_admin?
  end

  def destroy?
    user_is_owner_or_admin?
  end

  private

  def user_is_owner_or_admin?
    user.admin || record.school == user.school
  end
end
