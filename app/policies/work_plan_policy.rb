class WorkPlanPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.includes([:student]).where(user:,
        special_wps: false).order(created_at: :DESC)
      end

    end
    def show?
      user_is_owner_or_admin?
    end
    def create?
      true
    end

    def update?
      user_is_owner_or_admin?
    end

    def destroy?
    user_is_owner_or_admin?
    end

    def evaluation?
      user_is_owner_or_admin?
    end

    def auto_new_wp?
      true
    end

    private

    def user_is_owner_or_admin?
      user.admin || record.user.school == user.school
    end

end
