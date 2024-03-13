class SubscriptionPolicy < ApplicationPolicy
  # class Scope < Scope
  #   # NOTE: Be explicit about which records you allow access to!
  #   def resolve
  #     user.shared_classrooms
  #   end
  # end

  def school_pricing?
    true
  end

  def success?
    true
  end

  def on_boarding?
    user.admin? || true && user.school.valid_subscription?
  end

  # def new?
  #   create?
  # end

  def create?
    user.admin? || true && user.school.valid_subscription?
  end

  private

  def user_is_owner_or_admin?
    user.admin || record.classroom.user == user
  end
end
