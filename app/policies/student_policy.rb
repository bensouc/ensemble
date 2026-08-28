class StudentPolicy < ApplicationPolicy
  # class Scope < Scope
  #   # NOTE: Be explicit about which records you allow access to!
  #   def resolve

  #   end
  # end
  # Voir un élève, c'est voir sa classe : son enseignant, les collègues du
  # partage, les admins. `true` sans condition laissait n'importe quel
  # enseignant connecté ouvrir la fiche de n'importe quel élève — nom, ceintures,
  # progression — y compris dans une autre école.
  #
  # On délègue à `ClassroomPolicy` au lieu de recopier la règle : c'est déjà elle
  # qui décide qui accède à une classe, et l'unique chemin vers cette fiche est
  # `mobile/classrooms/:classroom_id/students/:id`.
  def show?
    ClassroomPolicy.new(user, record.classroom).show?
  end

  # Transférer un élève reste interne à son école.
  def transfer?
    user.admin? || record.school == user.school
  end
end
