class ClassroomPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.classrooms
    end
  end

  def create?
    # test demo, return true if authorize
    user_is_owner_or_admin? && create_classroom_demo? && sub_limit?
  end

  def results?
    user_is_owner_or_admin?
  end

  def results_by_domain?
    user_is_owner_or_admin?
  end

  def destroy?
    user_is_owner_or_admin?
  end

  private

  def create_classroom_demo?
    user.demo ? user.classrooms.count < 1 : true
  end

  def sub_limit?
    user.demo || (!user.school.subscription.nil? && user.school.subscription.quantity >= user.school.classrooms.count)
  end

  def user_is_owner_or_admin?
    user.admin || record.user == user || record.shared_classrooms.any? { |shared_classroom| shared_classroom.user == user }
  end
end
