# frozen_string_literal: true

module Manipule
  # Un problème de la série, et ce que l'élève en a fait.
  class Attempt < ApplicationRecord
    # Quatre états, et « skipped » ne se confond pas avec « wrong » : un
    # renoncement et un échec ne désignent ni les mêmes élèves ni la même
    # remédiation.
    STATUTS = %w[pending correct wrong skipped].freeze

    belongs_to :practice, inverse_of: :attempts
    belongs_to :problem
    belongs_to :choice, optional: true

    validates :status, inclusion: { in: STATUTS }
    validates :position, presence: true

    scope :repondues, -> { where.not(status: "pending") }
    scope :reussies, -> { where(status: "correct") }

    def repondue?
      status != "pending"
    end

    def repondre_par_choix!(choix, elapsed_ms: nil)
      enregistrer!(choix.correct? ? "correct" : "wrong", choice: choix, elapsed_ms:)
    end

    def repondre_par_saisie!(texte, elapsed_ms: nil)
      enregistrer!(problem.accepte?(texte) ? "correct" : "wrong", given: texte, elapsed_ms:)
    end

    def passer!
      enregistrer!("skipped")
    end

    def ecoute!
      increment!(:listened_count) # rubocop:disable Rails/SkipsModelValidations
    end

    private

    def enregistrer!(statut, choice: nil, given: nil, elapsed_ms: nil)
      update!(status: statut, choice:, given:, elapsed_ms:, answered_at: Time.current)
    end
  end
end
