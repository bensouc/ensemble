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

    # Le plateau des dizaines et des unités. Neuf barres : à dix, on aurait une
    # centaine, et ce n'est pas ce que l'outil enseigne. Trente unités en
    # réserve suffisent pour tout ce qui se joue en CP et en CE1.
    DIZAINES_MAX = 9
    UNITES_MAX = 30

    # Au-delà, l'écran de l'élève devient illisible et le geste perd son sens :
    # on ne range pas des pommes dans six endroits à la fois quand on a sept ans.
    ZONES_MAX = 6

    # L'horloge. Le cadran fait douze heures : une horloge à aiguilles ne
    # distingue pas trois heures de quinze heures, et c'est précisément ce
    # qu'elle apprend à lire.
    CADRAN = 12 * 60

    # Le pas de l'aiguille des minutes. Au CP on place les heures et les
    # demies ; viser la minute exacte à la souris n'apprend rien et décourage.
    PAS_HORLOGE = [1, 5, 15, 30].freeze
    PAS_PAR_DEFAUT = 5

    # Le partage. Des boîtes que l'ÉLÈVE ajoute et retire : combien de parts
    # faire est souvent LA question du problème, et la lui donner déjà faite
    # reviendrait à la résoudre à sa place.
    BOITES_MAX = 8

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

    # « Aucun » est une valeur du menu, et un menu renvoie une chaîne vide, pas
    # `nil` : sans cette normalisation, `allow_nil` ne s'appliquait pas et une
    # manipulation SANS outil était refusée — « Tool n'est pas inclus dans la
    # liste », sur un formulaire où l'enseignante n'avait rien choisi.
    normalizes :tool, with: -> (valeur) { valeur.presence }

    # Les messages et les noms des champs sont dans `fr.yml` : sans eux, Rails
    # montrait à l'enseignante le nom anglais de la colonne — « Statement doit
    # être rempli(e) », « Choices label… ».
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
    def outil?
      tool.present?
    end

    def jetons?
      tool == "jetons"
    end

    def dizaines_unites?
      tool == "dizaines_unites"
    end

    def horloge?
      tool == "horloge"
    end

    def partage?
      tool == "partage"
    end

    # Ce que l'enseignante pose sur le plateau avant que l'élève n'arrive :
    # l'énoncé dit « il y a 15 billes », le plateau montre 15. Rangé en barres
    # et en unités, comme l'élève l'aurait fait lui-même.
    def plateau_depart
      tool_data["depart"].to_i.clamp(0, (DIZAINES_MAX * 10) + 9)
    end

    def plateau_dizaines
      plateau_depart / 10
    end

    def plateau_unites
      plateau_depart % 10
    end

    # Le compte affiché peut DONNER la réponse : « en tout 12 », ou « à placer
    # 10 » sur un problème qui demande combien il reste — l'élève n'a plus qu'à
    # lire. L'enseignante décide donc problème par problème, pour TOUS les
    # outils, et c'est caché par défaut : on montre moins plutôt que de souffler
    # la réponse sans s'en rendre compte.
    def compteur?
      tool_data["compteur"].to_s == "1"
    end

    def jeton_caractere
      RESSOURCES.fetch(tool_data["ressource"], RESSOURCES["pomme"])
    end

    def jeton_reserve
      tool_data["reserve"].to_i.clamp(0, RESERVE_MAX)
    end

    # L'heure de départ, en minutes sur le cadran de douze heures. Elle place
    # le problème — « il est 3 h, la récréation est dans vingt minutes » — et
    # l'élève fait tourner les aiguilles à partir de là.
    def horloge_minutes
      tool_data["heure"].to_i.clamp(0, CADRAN - 1)
    end

    def horloge_pas
      pas = tool_data["pas"].to_i
      PAS_HORLOGE.include?(pas) ? pas : PAS_PAR_DEFAUT
    end

    # Ce qu'il y a à partager, et combien de boîtes sont posées au départ.
    # Zéro boîte est un départ légitime : « combien de paquets peux-tu
    # faire ? » commence par un plateau nu.
    def partage_objets
      tool_data["objets"].to_i.clamp(0, RESERVE_MAX)
    end

    def partage_boites
      tool_data["boites"].to_i.clamp(0, BOITES_MAX)
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

      errors.add(:base, :une_seule_bonne_reponse)
    end
  end
end
