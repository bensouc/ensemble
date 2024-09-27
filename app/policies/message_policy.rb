class MessagePolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  def show?
    true # Tout le monde peut voir les messages
  end

  def create?
    true # Tout le monde peut voir les messages
  end
end
