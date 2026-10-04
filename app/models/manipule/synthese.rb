# frozen_string_literal: true

module Manipule
  # La synthèse vocale, faite à l'avance plutôt que dans le navigateur de
  # l'élève.
  #
  # Pourquoi : la voix du navigateur est celle de la machine, et une salle de
  # classe n'en a pas forcément une en français — le poste sur lequel ce code a
  # été vérifié n'en avait aucune. Pré-générer, c'est garantir que tous les
  # élèves entendent la même chose, lisiblement, quel que soit l'ordinateur.
  #
  # Cette classe ne synthétise rien elle-même : elle choisit un moteur et lui
  # passe le texte. `Azure` dès qu'une clé est configurée, `Systeme` sinon —
  # celui-ci s'appuie sur `say` et ne sert qu'au développement.
  class Synthese
    # L'adaptateur ne peut pas travailler, et réessayer n'y changera rien :
    # le job qui la reçoit la jette au lieu de la relancer cinq fois.
    class Indisponible < StandardError; end

    # L'allocation du fournisseur est consommée, ou on a refusé d'aller plus
    # loin. Même traitement : on ne relance pas.
    class Quota < Indisponible; end

    # La phrase qui sert à juger une voix : deux phrases pour entendre le
    # silence entre elles, une question pour entendre l'intonation, et le
    # vocabulaire d'un vrai énoncé.
    PHRASE_TEMOIN = "Il y a quinze pommes sur le pommier. Sam cueille sept pommes. " \
                    "Combien reste-t-il de pommes sur le pommier ?"

    # Ce que rend une synthèse : les octets et de quoi savoir ce qui les a
    # produits. Les faire voyager ensemble évite de les perdre en route.
    Rendu = Struct.new(:octets, :content_type, :voix, keyword_init: true)

    # `MANIPULE_TTS=systeme` force la voix locale : de quoi itérer sur un
    # énoncé sans entamer l'allocation distante à chaque reformulation.
    def self.moteur
      case ENV["MANIPULE_TTS"].presence
      when "azure" then Azure
      when "systeme" then Systeme
      else Azure.disponible? ? Azure : Systeme
      end
    end

    def self.disponible?
      moteur.disponible?
    end

    def self.voix_defaut
      moteur::VOIX_DEFAUT
    end

    def self.debit_defaut
      moteur::DEBIT_DEFAUT
    end

    # Les voix françaises que le moteur courant sait produire, pour choisir à
    # l'oreille plutôt que sur le nom.
    def self.echantillons(phrase, dossier)
      FileUtils.mkdir_p(dossier)
      moteur.voix_disponibles.map do |voix|
        rendu = new(voix:).generer(phrase)
        chemin = Pathname(dossier).join("#{voix.gsub(/\W+/, '_')}#{extension(rendu.content_type)}")
        File.binwrite(chemin, rendu.octets)
        [voix, chemin]
      end
    end

    def self.extension(content_type)
      { "audio/mpeg" => ".mp3", "audio/mp4" => ".m4a" }.fetch(content_type, ".bin")
    end

    # `voix` est la voix réellement retenue — celle du moteur, pas celle
    # demandée, qui peut être nulle. `GenerationAudio` s'en sert pour savoir
    # si un morceau déjà en base a été dit par la même voix.
    delegate :voix, :generer, to: :moteur

    def initialize(voix: nil, debit: nil, moteur: nil)
      @moteur = (moteur || self.class.moteur).new(voix:, debit:)
    end

    # Le nombre de caractères que le fournisseur offre chaque mois, quand il y
    # en a un. Sert à situer ce qu'une fabrication vient de consommer.
    def allocation_mensuelle
      @moteur.class.try(:allocation_mensuelle)
    end

    private

    attr_reader :moteur
  end
end
