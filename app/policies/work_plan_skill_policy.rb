class WorkPlanSkillPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
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

  def destroy?
    user_is_owner_or_admin?
  end

  def eval_update?
    user_is_owner_or_admin?
  end

  def change_challenge?
    user_is_owner_or_admin?
  end

  def add_validated_wps?
    user_is_owner_or_admin?
  end

  def remove_special_wps?
    user_is_owner_or_admin?
  end

  private

  def user_is_owner_or_admin?
    user.admin || record.work_plan_domain.work_plan.user.school == user.school
  end
end
