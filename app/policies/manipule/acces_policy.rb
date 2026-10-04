# frozen_string_literal: true

module Manipule
  # Qui peut ouvrir l'option Manipule, et à qui.
  #
  # Les admins, et eux seuls. Ce n'est pas une donnée d'école qu'une
  # enseignante gérerait pour ses collègues : c'est l'interrupteur d'un essai,
  # et il reste entre les mains de ceux qui conduisent l'essai.
  class AccesPolicy < ApplicationPolicy
    class Scope < ApplicationPolicy::Scope
      def resolve
        user.admin? ? scope.all : scope.none
      end
    end

    def index?
      user.admin?
    end

    def update?
      user.admin?
    end
  end
end
