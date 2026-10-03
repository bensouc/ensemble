class WorkPlanDomainPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  # Un domaine du plan se lit et se gère comme le plan (`WorkPlanPolicy`).
  delegate :show?, :update?, to: :plan_policy

  def destroy?
    update?
  end

  private

  def plan_policy
    WorkPlanPolicy.new(user, record.work_plan)
  end
end
