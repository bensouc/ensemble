class WorkPlanDomainPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end
  def destroy?
    user_is_owner_or_admin?
  end

  def update?
    user_is_owner_or_admin?
  end
  private

  def user_is_owner_or_admin?
    user.admin || record.work_plan.user.school == user.school
  end

end
