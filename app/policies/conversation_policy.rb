class ConversationPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def show?
    user_is_participant?
  end

  def contact_user?
    true
  end

  def add_user?
    user_is_participant?
  end

  def update?
    user_is_participant?
  end

  def edit?
    update?
  end

  private

  def user_is_participant?
    user.admin? || record.users.include?(user)
  end
end
