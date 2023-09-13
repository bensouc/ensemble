class BeltPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def edit?
    user_is_owner_or_admin?
  end

  def create?
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
    user.admin ||
      record.student.classroom.user == user ||
      record.student.shared_classrooms.any? { |shared_classroom| shared_classroom.user == user }
  end
end
