# frozen_string_literal: true

module Manipule
  # Fabrique l'audio manquant ou périmé d'une banque.
  #
  # Ne refait que ce qui doit l'être : un morceau dont le texte et la voix
  # n'ont pas bougé est laissé tel quel. C'est le garde-fou qui compte, bien
  # avant le plafond ci-dessous — corriger un mot d'énoncé coûte un morceau,
  # pas une banque.
  class GenerationAudio
    # Deux fois la banque entière telle qu'on l'imagine. Ce plafond n'est pas
    # là pour rationner mais pour arrêter une boucle qui s'emballe : une
    # régénération en série qui partirait de travers consommerait l'allocation
    # du mois avant que quiconque s'en aperçoive.
    PLAFOND_CARACTERES = 50_000

    attr_reader :faits, :sautes, :caracteres

    def initialize(voix: nil, debit: nil, skill_id: nil, trace: nil, plafond: PLAFOND_CARACTERES)
      @synthese = Synthese.new(voix:, debit:)
      @skill_id = skill_id
      @trace = trace
      @plafond = plafond
      @faits = 0
      @sautes = 0
      @caracteres = 0
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

    # Ce qu'une exécution vient de coûter, en caractères — l'unité de
    # facturation des voix neuronales — et ce qu'elle laisse en base.
    def resume
      [
        "#{faits} morceaux générés, #{sautes} déjà à jour.",
        "#{caracteres} caractères consommés#{part_de_l_allocation}.",
        "Total en base : #{total_en_base} morceaux, #{megaoctets_en_base} Mo."
      ]
    end

    def total_en_base
      Audio.count
    end

    def megaoctets_en_base
      (Audio.sum(:octets) / 1024.0 / 1024).round(1)
    end

    private

    # La voix du système n'a pas d'allocation : on ne raconte pas de
    # pourcentage quand il n'y a rien à consommer.
    def part_de_l_allocation
      allocation = @synthese.allocation_mensuelle
      return "" if allocation.blank?

      ", soit #{(caracteres * 100.0 / allocation).round(2)} % de l'allocation mensuelle"
    end

    def problemes
      portee = Problem.includes(:choices)
      @skill_id.present? ? portee.where(skill_id: @skill_id) : portee
    end

    def traiter(element, role, texte)
      return if texte.blank?
      return @sautes += 1 if a_jour?(element, role, texte)

      compter(texte)
      Audio.poser!(readable: element, role:, texte:, rendu: @synthese.generer(texte))
      @faits += 1
      @trace&.call
    end

    # Les caractères sont l'unité de facturation des voix neuronales, et celle
    # de l'allocation mensuelle. On compte ce qu'on s'apprête à dire, et on
    # s'arrête avant de le dire si le compte dérape.
    def compter(texte)
      @caracteres += texte.length
      return if @caracteres <= @plafond

      raise Synthese::Quota,
            "Plafond de #{@plafond} caractères atteint en une seule exécution " \
            "(#{@faits} morceaux déjà générés). Relance avec un plafond explicite si c'est voulu."
    end

    def a_jour?(element, role, texte)
      existant = Audio.find_by(readable: element, role:)
      existant.present? && !existant.perime?(texte) && existant.voix == @synthese.voix
    end
  end
end
