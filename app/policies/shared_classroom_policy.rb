class SharedClassroomPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.shared_classrooms
    end
  end

  def create?
    user_is_owner_or_admin?
  end


  private

  def user_is_owner_or_admin?
    user.admin || record.classroom.user == user
  end
end
