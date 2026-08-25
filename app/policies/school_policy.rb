class SchoolPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.school
    end
  end

  def new?
    true
  end

  def create?
    true
  end

  def join?
    true
  end

  def show?
    record.users.any? { |school_user| school_user == user }
  end

  # Inviter, c'est ouvrir l'accès aux classes et aux élèves du groupe :
  # c'est au responsable d'en décider.
  def invite_teacher?
    show? && user.school_role&.super_teacher? == true
  end

  # Renouveler le code coupe l'accès de tous ceux qui détiennent l'ancien :
  # c'est au responsable du groupe d'en décider, pas à n'importe quel membre.
  def renew_code?
    show? && user.school_role&.super_teacher? == true
  end
end
