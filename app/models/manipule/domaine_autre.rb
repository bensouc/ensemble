# frozen_string_literal: true

module Manipule
  # « Autre » : le domaine où ranger ce qui ne relève d'aucune compétence
  # d'Ensemble, sans pour autant le laisser flotter.
  #
  # C'est un vrai `Domain`, pas une table à part : il a son niveau, ses
  # compétences et leurs ceintures, et c'est précisément ce qu'on veut en
  # réutiliser — l'affectation à un élève, le cloisonnement par école et la
  # série passent tous par une compétence.
  #
  # Son drapeau `manipule` le rend invisible d'Ensemble : il n'apparaît ni dans
  # la progression d'un élève, ni dans la grille de ceintures, ni dans la
  # génération des plans de travail. Voir `Grade#domains`.
  #
  # Un seul par niveau : l'index unique `(grade_id, name)` le garantit en base,
  # et `find_or_create_by!` s'appuie dessus.
  class DomaineAutre
    NOM = "Autre"

    def self.pour!(niveau)
      Domain.find_or_create_by!(name: NOM, grade: niveau, manipule: true)
    end

    def self.pour(niveau)
      Domain.find_by(name: NOM, grade: niveau, manipule: true)
    end

    # La compétence que l'enseignante nomme elle-même, à la ceinture qu'elle
    # choisit. L'école vient du niveau, jamais de l'utilisateur : le
    # `school_id` d'une compétence et celui du niveau de son domaine peuvent
    # diverger, et c'est de là que venait la fuite entre écoles.
    #
    # Sous transaction : sans elle, un nom vide laisserait derrière lui un
    # domaine « Autre » créé pour rien, et vide.
    def self.ajouter_competence!(niveau:, nom:, ceinture:)
      Domain.transaction do
        Skill.create!(name: nom, domain: pour!(niveau), school: niveau.school,
                      level: ceinture, symbol: "")
      end
    end
  end
end
