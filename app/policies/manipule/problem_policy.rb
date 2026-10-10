# frozen_string_literal: true

module Manipule
  # Un problème appartient à l'école par sa compétence. Mêmes règles que pour
  # les exercices d'Ensemble : les enseignants de l'école, et les admins.
  class ProblemPolicy < ApplicationPolicy
    class Scope < ApplicationPolicy::Scope
      # Même un admin ne voit ici que SON école. Ces trois écrans — l'accueil,
      # la banque, « Autre » — sont la banque de l'enseignante, pas une console
      # d'administration.
      #
      # Le laissez-passer admin y faisait entrer les manipulations de toutes
      # les écoles, mélangées et sans dire à qui elles appartenaient. Et elles
      # étaient INATTEIGNABLES : les filtres, eux, s'arrêtent aux niveaux de
      # ses propres classes, donc aucune combinaison ne pouvait les retrouver.
      # Vu en production, sur un compte qui voyait le CE1 d'une autre école au
      # milieu du sien — deux niveaux portant le même nom, par-dessus le
      # marché.
      #
      # « Rien au-dessus de l'école » est la règle d'Ensemble. Le laissez-passer
      # reste sur `de_son_ecole?` : un admin peut toujours ouvrir une compétence
      # qu'on lui nomme, pour dépanner. Il ne dicte plus ce qu'on LISTE.
      def resolve
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
