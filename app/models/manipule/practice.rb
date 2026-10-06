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
    def self.commencer!(student:, skill:, size: TAILLE)
      problemes = choisir(student:, skill:, size:)
      raise ArgumentError, "Aucun problème visible pour cette compétence" if problemes.empty?

      transaction do
        serie = create!(student:, skill:, started_at: Time.current, size: problemes.size)
        problemes.each_with_index { |probleme, i| serie.attempts.create!(problem: probleme, position: i + 1) }
        serie
      end
    end

    # Les dix de la séance, en trois rangs :
    #
    #   1. ce qu'il n'a jamais fait, DANS L'ORDRE DE L'ENSEIGNANTE ;
    #   2. ce qu'il a raté ou passé sans jamais le réussir, le plus ancien
    #      d'abord — on y revient, mais on ne s'acharne pas le même jour ;
    #   3. ce qu'il a déjà réussi, le plus ancien d'abord, pour compléter.
    #
    # Avant, c'était `ORDER BY RANDOM()` : l'ordre que l'enseignante donne à
    # ses problèmes ne servait à rien, et l'élève pouvait retomber le lendemain
    # sur les dix mêmes alors qu'il en restait vingt jamais vus. C'était la
    # Q30, restée sans réponse.
    #
    # Une tentative restée en attente ne compte pas comme vue : un problème
    # affiché mais jamais répondu doit revenir.
    def self.choisir(student:, skill:, size:)
      visibles = Problem.published.where(skill:).order(:position, :id).to_a
      histoire = historique(student:, problemes: visibles)
      visibles.each_with_index.sort_by do |probleme, ordre_de_la_prof|
        passe = histoire[probleme.id]
        [rang(passe), passe ? passe[:dernier] : 0, ordre_de_la_prof]
      end.first(size).map(&:first)
    end

    def self.rang(passe)
      return 1 if passe.nil?

      passe[:reussi] ? 3 : 2
    end

    # Une seule requête : par problème, la dernière fois qu'il y a répondu, et
    # s'il l'a déjà réussi au moins une fois.
    def self.historique(student:, problemes:)
      Attempt.repondues.joins(:practice).
        where(manipule_practices: { student_id: student.id }, problem_id: problemes.map(&:id)).
        group(:problem_id).
        pluck(Arel.sql("manipule_attempts.problem_id, MAX(manipule_attempts.answered_at), " \
                       "MAX(CASE WHEN manipule_attempts.status = 'correct' THEN 1 ELSE 0 END)")).
        to_h { |id, dernier, reussi| [id, { dernier: dernier.to_f, reussi: reussi == 1 }] }
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
