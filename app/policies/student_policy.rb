class StudentPolicy < ApplicationPolicy
  # La Scope était commentée, si bien que `policy_scope(Student)` retombait sur
  # `ApplicationPolicy::Scope`, dont `resolve` lève NotImplementedError :
  # `mobile/students#index` répondait 500 depuis toujours.
  #
  # Les élèves visibles sont ceux des classes qu'on peut voir — les siennes et
  # celles qui nous sont partagées. Même règle que `show?` ci-dessous.
  class Scope < Scope
    def resolve
      return scope.all if user.admin?

      scope.where(classroom_id: user.classrooms.ids + user.user_shared_classrooms.ids)
    end
  end

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
