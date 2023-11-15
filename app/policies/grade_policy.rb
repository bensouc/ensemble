class GradePolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.includes([:classrooms, :students]).where(school: user.school)
    end
  end
end
