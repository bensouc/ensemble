# frozen_string_literal: true

module Manipule
  # Un problème : un énoncé en texte simple, une question, et une réponse —
  # soit trois choix, soit une valeur à saisir. L'enseignante tranche exercice
  # par exercice.
  class Problem < ApplicationRecord
    MODES = %w[choix saisie].freeze
    OUTILS = %w[jetons partage horloge dizaines_unites].freeze

    # Les jetons que l'enseignante peut faire manipuler. Des caractères, pas
    # des images : rien à téléverser, rien à servir, et ça s'affiche sur la
    # machine du fond de la classe comme sur un iPad.
    RESSOURCES = {
      "pomme" => "🍎", "lapin" => "🐰", "carotte" => "🥕", "biscuit" => "🍪",
      "bille" => "🔵", "piece" => "🪙", "fleur" => "🌸", "etoile" => "⭐"
    }.freeze

    RESERVE_MAX = 30

    # Au-delà, l'écran de l'élève devient illisible et le geste perd son sens :
    # on ne range pas des pommes dans six endroits à la fois quand on a sept ans.
    ZONES_MAX = 6

    belongs_to :skill
    belongs_to :user, optional: true

    has_many :choices, -> { order(:position) }, inverse_of: :problem, dependent: :destroy
    # Un problème déjà passé par un élève ne se supprime pas : son historique
    # ferait mentir le suivi. On le retire de la circulation (`published`).
    has_many :attempts, inverse_of: :problem, dependent: :restrict_with_error

    # L'audio s'accroche par un lien polymorphe, donc sans clef étrangère :
    # rien, en base, ne l'emporterait avec son porteur. Sans ceci, supprimer
    # un problème laisserait ses morceaux de voix orphelins pour toujours.
    has_many :audios, as: :readable, class_name: "Manipule::Audio", dependent: :destroy

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

    # Les réglages de l'outil, lus depuis la colonne structurée. L'outil aide
    # l'élève à se représenter le problème ; il ne porte PAS la réponse, qui
    # reste un choix ou une saisie. C'est ce qui a été tranché au cadrage :
    # « le prof peut soit demander un QCM soit une valeur à entrer ».
    def jetons?
      tool == "jetons"
    end

    def jeton_caractere
      RESSOURCES.fetch(tool_data["ressource"], RESSOURCES["pomme"])
    end

    def jeton_reserve
      tool_data["reserve"].to_i.clamp(0, RESERVE_MAX)
    end

    # Des zones nommées d'après l'énoncé — « le panier de Sam », « restées sur
    # l'arbre ». Un nom vide ne donnerait qu'un rectangle muet.
    def jeton_zones
      Array(tool_data["zones"]).map(&:to_s).map(&:strip).reject(&:empty?).first(ZONES_MAX)
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

      errors.add(:base, "Une manipulation doit avoir exactement une bonne réponse")
    end
  end
end
