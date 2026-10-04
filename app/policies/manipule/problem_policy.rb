# frozen_string_literal: true

module Manipule
  # Un problème appartient à l'école par sa compétence. Mêmes règles que pour
  # les exercices d'Ensemble : les enseignants de l'école, et les admins.
  class ProblemPolicy < ApplicationPolicy
    class Scope < ApplicationPolicy::Scope
      def resolve
        return scope.all if user.admin?

        # `User` n'a pas de colonne `school_id` : son école passe par
        # `school_role`, et peut manquer sur une inscription abandonnée.
        scope.joins(:skill).where(skills: { school_id: user.school&.id })
      end
    end

    def index?
      true
    end

    def show?
      de_son_ecole?
    end

    def create?
      de_son_ecole?
    end

    def update?
      de_son_ecole?
    end

    def destroy?
      de_son_ecole?
    end

    def importer?
      create?
    end

    def publier?
      update?
    end

    private

    def de_son_ecole?
      user.admin || ecole_du_record == user.school
    end

    def ecole_du_record
      record.is_a?(Skill) ? record.school : record.skill&.school
    end
  end
end
