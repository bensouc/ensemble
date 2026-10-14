# frozen_string_literal: true

# Une fiche de ceinture est celle d'un élève : qui voit l'élève — son
# enseignant, les collègues du partage, un admin — voit et prépare ses fiches.
# Une fiche non assignée n'est qu'à son auteur. Les blocs et les lignes
# s'autorisent par leur fiche.
class BeltSheetPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(student: StudentPolicy::Scope.new(user, Student).resolve).
        or(scope.non_assignees.where(user:))
    end
  end

  def show?
    return user.admin? || record.user_id == user.id if record.non_assignee?

    StudentPolicy.new(user, record.student).show?
  end

  # Préparer une fiche demande que la classe de l'élève ait ouvert les fiches de
  # ceinture. Les fiches déjà faites restent lisibles et modifiables si le
  # réglage est coupé ensuite : on masque les entrées, on ne retire rien.
  #
  # En générer une non assignée demande une classe aux fiches de ceinture — les
  # exercices de ceinture n'existent que pour elle —, et un niveau de son école.
  def create?
    return Classroom.belt_sheets_for?(user) && GradePolicy.new(user, record.grade).show? if record.non_assignee?

    show? && record.student.classroom.belt_sheets?
  end

  def update?
    show?
  end

  def destroy?
    show?
  end

  # Cloner vers d'autres élèves part de l'élève de la fiche : une fiche non
  # assignée ne se distribue pas (encore).
  def clone?
    show? && !record.non_assignee?
  end
end
