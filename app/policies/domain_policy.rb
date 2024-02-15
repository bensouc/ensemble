class DomainPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end
  def show?
    user.admin? || record.grade.school == user.school
  end


  def create?
    user.admin? || record.grade.school == user.school
  end

  def destroy?
    user.admin? || record.grade.school == user.school
  end
    def update?
    user.admin? || record.grade.school == user.school
  end
end
