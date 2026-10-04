# frozen_string_literal: true

module Manipule
  # Un morceau d'audio : un énoncé, une question, ou une réponse.
  #
  # Un fichier par élément lisible, et non un seul par problème : l'élève doit
  # pouvoir réécouter une réponse seule, autant de fois qu'il veut.
  class Audio < ApplicationRecord
    ROLES = %w[enonce question choix].freeze

    belongs_to :readable, polymorphic: true

    validates :role, inclusion: { in: ROLES }
    validates :texte_source, presence: true
    validates :data, presence: true

    # L'enseignante a corrigé l'énoncé : l'audio dit encore l'ancienne version.
    def perime?(texte)
      texte_source != texte.to_s
    end

    def self.poser!(readable:, role:, texte:, rendu:)
      audio = find_or_initialize_by(readable:, role:)
      audio.update!(texte_source: texte, data: rendu.octets, content_type: rendu.content_type,
                    voix: rendu.voix, octets: rendu.octets.bytesize)
      audio
    end
  end
end
