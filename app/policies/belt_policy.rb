class BeltPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def edit?
    user_is_owner_or_admin?
  end

  def create?
    user_is_owner_or_admin?
  end

  def update?
    user_is_owner_or_admin?
  end

  def destroy?
    user_is_owner_or_admin?
  end

  private

  # Les ceintures d'un élève se gèrent comme l'élève lui-même : son enseignant,
  # les collègues du partage, les admins. La règle cherchait le partage sur
  # `student.shared_classrooms`, une association qui n'existe pas — le collègue
  # du partage tombait sur une erreur 500 au lieu d'accéder à la ceinture.
  def user_is_owner_or_admin?
    StudentPolicy.new(user, record.student).update?
  end
end
