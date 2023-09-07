class ChallengePolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def show?
    user_is_owner_or_admin?
  end

  def update?
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
      user.admin || record.user.school == user.school
    end
end
