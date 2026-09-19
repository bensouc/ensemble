class ResultPolicy < ApplicationPolicy
  # class Scope < Scope
  #   # NOTE: Be explicit about which records you allow access to!
  #   def resolve

  #   end
  # end
  def create?
    user_is_teacher_or_admin?
  end

  def validate?
    user_is_teacher_or_admin?
  end

  # Le masquage du « − » dans la grille ne protège de rien : la route reste
  # ouverte à qui connaît l'identifiant.
  def destroy?
    user_is_teacher_or_admin? && record.deletable?
  end

  private

  def user_is_teacher_or_admin?
    user.admin ||
      record.student.classroom.user == user ||
      record.student.classroom.shared_classrooms.any? { |shared_classroom| shared_classroom.user == user }
  end
end
