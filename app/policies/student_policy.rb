class StudentPolicy < ApplicationPolicy
  # class Scope < Scope
  #   # NOTE: Be explicit about which records you allow access to!
  #   def resolve

  #   end
  # end
  def show?
    true
  end

  # Transférer un élève reste interne à son école.
  def transfer?
    user.admin? || record.school == user.school
  end
end
