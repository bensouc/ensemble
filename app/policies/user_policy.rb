class UserPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def add_discovery_method?
    user.discovery_method.nil?
  end

  # Écrire à quelqu'un, ou l'ajouter à une conversation : la messagerie est celle
  # de l'école, on n'y retrouve que ses collègues. Un admin écrit à tout le monde.
  def contact?
    user.admin? || user.collegues.include?(record)
  end
end
