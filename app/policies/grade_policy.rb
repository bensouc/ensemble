class GradePolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.includes([:classrooms, :students]).where(school: user.school)
    end
  end

  # Parcourir les compétences ou les exercices d'un niveau : ceux de son école.
  # Les index les filtrent sur un niveau désigné par la requête.
  def show?
    user.admin? || record.school == user.school
  end

  def create?
    record.school == user.school
  end

  def destroy?
    record.school == user.school && user.super_teacher?
  end
end
