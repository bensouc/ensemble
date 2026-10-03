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

  delegate :show?, to: :plan_policy

  def update?
    user_is_owner_or_admin?
  end

  def destroy?
    user_is_owner_or_admin?
  end

  def eval_update?
    plan_policy.evaluation?
  end

  def change_challenge?
    user_is_owner_or_admin?
  end

  def add_validated_wps?
    user_is_owner_or_admin?
  end

  def move?
    user_is_owner_or_admin?
  end

  def pick_challenge?
    user_is_owner_or_admin?
  end

  def create_empty_challenge?
    user_is_owner_or_admin?
  end

  private

  # Une compétence du plan se lit, s'évalue et se gère comme le plan
  # (`WorkPlanPolicy`) : qui suit l'élève.
  def user_is_owner_or_admin?
    plan_policy.update?
  end

  def plan_policy
    WorkPlanPolicy.new(user, record.work_plan_domain.work_plan)
  end
end
