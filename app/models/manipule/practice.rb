# frozen_string_literal: true

module Manipule
  # Une série : ce que l'application sort de la banque pour une séance d'élève.
  # Dix problèmes tirés au hasard sur une compétence, différents à chaque fois.
  class Practice < ApplicationRecord
    TAILLE = 10

    belongs_to :student
    belongs_to :skill

    has_many :attempts, -> { order(:position) }, inverse_of: :practice, dependent: :destroy

    scope :terminees, -> { where.not(finished_at: nil) }

    # Les tentatives sont créées d'avance, en « pending » : savoir qu'un élève
    # s'est arrêté au quatrième problème est une information que l'enseignante
    # veut. Les créer à la réponse perdrait la trace d'une série abandonnée.
    #
    # Tirage sans mémoire : l'élève peut retomber demain sur les mêmes
    # problèmes. C'est la Q30, restée sans réponse ; le jour où elle sera
    # tranchée, c'est cette méthode, et elle seule, qui changera.
    def self.commencer!(student:, skill:, size: TAILLE)
      problemes = Problem.published.where(skill:).order(Arel.sql("RANDOM()")).limit(size).to_a
      raise ArgumentError, "Aucun problème visible pour cette compétence" if problemes.empty?

      transaction do
        serie = create!(student:, skill:, started_at: Time.current, size: problemes.size)
        problemes.each_with_index { |probleme, i| serie.attempts.create!(problem: probleme, position: i + 1) }
        serie
      end
    end

    def terminer!
      update!(finished_at: Time.current)
    end

    def terminee?
      finished_at.present?
    end

    def duree
      return nil unless terminee?

      finished_at - started_at
    end
  end
end
