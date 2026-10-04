# frozen_string_literal: true

module Manipule
  # Un problème : un énoncé en texte simple, une question, et une réponse —
  # soit trois choix, soit une valeur à saisir. L'enseignante tranche exercice
  # par exercice.
  class Problem < ApplicationRecord
    MODES = %w[choix saisie].freeze
    OUTILS = %w[jetons partage horloge dizaines_unites].freeze

    belongs_to :skill
    belongs_to :user, optional: true

    has_many :choices, -> { order(:position) }, inverse_of: :problem, dependent: :destroy
    # Un problème déjà passé par un élève ne se supprime pas : son historique
    # ferait mentir le suivi. On le retire de la circulation (`published`).
    has_many :attempts, inverse_of: :problem, dependent: :restrict_with_error

    accepts_nested_attributes_for :choices, allow_destroy: true

    validates :statement, presence: true
    validates :question, presence: true
    validates :answer_mode, inclusion: { in: MODES }
    validates :tool, inclusion: { in: OUTILS }, allow_nil: true
    validates :answer, presence: true, if: :saisie?
    validate :exactement_une_bonne_reponse, if: :choix?

    # L'audio se fabrique quand le problème entre en circulation, et se refait
    # quand son texte change alors qu'il y est déjà. Un brouillon ne coûte rien :
    # personne ne l'écoute.
    after_commit :programmer_audio, on: %i[create update]

    scope :published, -> { where(published: true) }

    delegate :level, to: :skill

    # Ce qu'il y a à lire, dans l'ordre où on le lit : l'énoncé, la question,
    # puis chaque réponse. Un morceau d'audio par élément, pour que l'élève
    # puisse revenir sur une réponse seule.
    def parties_a_lire
      [[self, "enonce", statement], [self, "question", question]] +
        choices.map { |choix| [choix, "choix", choix.label] }
    end

    def choix?
      answer_mode == "choix"
    end

    def saisie?
      answer_mode == "saisie"
    end

    # Accepte la réponse avec ou sans son unité, et se rabat sur les seuls
    # chiffres : « 9h45 » vaut « 9 h 45 ». La saisie ne porte que sur des
    # nombres — les mots restent hors périmètre, parce que les juger sans
    # adulte à côté ferait voir des rouges injustes.
    def accepte?(saisie)
      return false if saisie.blank?

      attendu = [answer, [answer, unit].compact_blank.join(" ")].map { |v| normalise(v) }
      return true if attendu.include?(normalise(saisie))

      chiffres(saisie).present? && chiffres(saisie) == chiffres(answer)
    end

    private

    def programmer_audio
      return unless published?
      return unless saved_change_to_published? || saved_change_to_statement? || saved_change_to_question?

      GenererAudioJob.perform_later(self)
    end

    def normalise(texte)
      texte.to_s.downcase.gsub(/\s+/, "").delete(".,;:!?")
    end

    def chiffres(texte)
      texte.to_s.scan(/\d+/).join("-")
    end

    # La seule chose qui, dans toute l'application, peut faire voir un rouge
    # injuste à un élève que personne n'est là pour rassurer : un problème sans
    # bonne réponse, ou avec deux. Ça se vérifie à l'enregistrement.
    def exactement_une_bonne_reponse
      vivantes = choices.reject(&:marked_for_destruction?)
      return if vivantes.one?(&:correct?)

      errors.add(:base, "Un problème doit avoir exactement une bonne réponse")
    end
  end
end
