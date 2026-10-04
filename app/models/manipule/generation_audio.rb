# frozen_string_literal: true

module Manipule
  # Fabrique l'audio manquant ou périmé d'une banque.
  #
  # Ne refait que ce qui doit l'être : un morceau dont le texte et la voix n'ont
  # pas bougé est laissé tel quel. Régénérer une banque complète coûterait une
  # minute, mais la rejouer à chaque import coûterait une minute à chaque fois.
  class GenerationAudio
    attr_reader :faits, :sautes

    def initialize(voix: Synthese::VOIX_DEFAUT, debit: Synthese::DEBIT_DEFAUT, skill_id: nil, trace: nil)
      @synthese = Synthese.new(voix:, debit:)
      @voix = voix
      @skill_id = skill_id
      @trace = trace
      @faits = 0
      @sautes = 0
    end

    def executer!
      problemes.find_each { |probleme| traiter_probleme(probleme) }
      self
    end

    # Chaque partie séparément — l'énoncé, la question, chaque réponse — et
    # seulement celles qui ont changé. Corriger un mot d'énoncé ne refait pas
    # les trois réponses.
    def traiter_probleme(probleme)
      probleme.parties_a_lire.each { |element, role, texte| traiter(element, role, texte) }
      self
    end

    def total_en_base
      Audio.count
    end

    def megaoctets_en_base
      (Audio.sum(:octets) / 1024.0 / 1024).round(1)
    end

    private

    def problemes
      portee = Problem.includes(:choices)
      @skill_id.present? ? portee.where(skill_id: @skill_id) : portee
    end

    def traiter(element, role, texte)
      return if texte.blank?
      return @sautes += 1 if a_jour?(element, role, texte)

      Audio.poser!(readable: element, role:, texte:, rendu: @synthese.generer(texte))
      @faits += 1
      @trace&.call
    end

    def a_jour?(element, role, texte)
      existant = Audio.find_by(readable: element, role:)
      existant.present? && !existant.perime?(texte) && existant.voix == @voix
    end
  end
end
