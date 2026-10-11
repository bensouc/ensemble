# frozen_string_literal: true

# Une fiche de ceinture est celle d'un élève : qui voit l'élève — son
# enseignant, les collègues du partage, un admin — voit et prépare ses fiches.
# Les blocs et les lignes s'autorisent par leur fiche.
class BeltSheetPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(student: StudentPolicy::Scope.new(user, Student).resolve)
    end
  end

  def show?
    StudentPolicy.new(user, record.student).show?
  end

  # Préparer une fiche demande que la classe de l'élève ait ouvert les fiches de
  # ceinture. Les fiches déjà faites restent lisibles et modifiables si le
  # réglage est coupé ensuite : on masque les entrées, on ne retire rien.
  def create?
    show? && record.student.classroom.belt_sheets?
  end

  def update?
    show?
  end

  def destroy?
    show?
  end
end
