class ConversationPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end
  def show?
    user.admin? || user_is_participant?
  end

  private

  def user_is_participant?
    record.users.include?(user)
  end
end
