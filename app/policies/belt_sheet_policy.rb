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

  def create?
    show?
  end

  def update?
    show?
  end

  def destroy?
    show?
  end
end
