# frozen_string_literal: true

require "net/http"

module Manipule
  class Synthese
    # Azure AI Speech, les voix neuronales de Microsoft.
    #
    # Attention au nom : le service visé est une *ressource* Azure, créée
    # depuis « Créer une ressource → Speech », au niveau tarifaire F0. Ce n'est
    # pas la même chose qu'une offre « Text-to-Speech API » achetée sur la
    # Place de marché Azure — celles-là sont des SaaS d'éditeurs tiers, que
    # Microsoft se contente de revendre, et leur clé ne vaut rien ici. Le 401
    # ci-dessous le rappelle, parce que l'erreur a déjà été faite.
    #
    # On ne synthétise pas pendant qu'un élève écoute : la banque est fabriquée
    # à l'avance et servie depuis notre base. Ce moteur ne tourne donc qu'à la
    # mise en circulation d'un problème, ou à la main.
    class Azure
      # Choisie à l'oreille parmi les trente et une voix françaises de la
      # région, le 2026-10-04. Les voix neuronales classiques — Denise, Henri —
      # datent de 2019 et sont devenues celles qu'on entend dans le navigateur ;
      # Soleil appartient à la génération suivante. Elle est aussi la plus
      # posée du lot, dix secondes là où Marc en met six pour la même phrase,
      # et le débit compte autant que le timbre pour un enfant qui ne décode
      # pas. Elle porte enfin dix-huit styles expressifs, dont « softvoice », si
      # l'on veut un jour adoucir la lecture.
      VOIX_DEFAUT = "fr-FR-Soleil:MAI-Voice-2.1"
      DEBIT_DEFAUT = -10 # en pour cent de la vitesse nominale
      SILENCE_ENTRE_PHRASES_MS = 600
      CONTENT_TYPE = "audio/mpeg"
      LOCALE = "fr-FR"

      # 24 kHz : le double de ce que donnent les modèles optimisés pour
      # l'inférence locale, et la différence s'entend sur un haut-parleur de
      # classe. 48 kbit/s suffisent largement pour de la parole.
      FORMAT = "audio-24khz-48kbitrate-mono-mp3"

      # Le palier gratuit F0 plafonne à 20 requêtes par tranche de 60 secondes,
      # et ce quota-là n'est pas ajustable. Trois secondes entre deux appels
      # nous tiennent dessous sans jamais y penser. Une banque de 100 problèmes
      # fait 500 morceaux, donc 25 minutes — c'est une fabrication, pas une
      # page web, personne n'attend devant.
      CADENCE_MINIMALE = 3.0

      # Ce que le palier gratuit F0 offre chaque mois. La banque entière en
      # consomme environ 2 %.
      ALLOCATION_MENSUELLE = 500_000
      REESSAIS = 3
      DELAI_OUVERTURE = 5
      DELAI_LECTURE = 30

      @verrou = Mutex.new

      attr_reader :voix

      class << self
        attr_reader :verrou

        def cle
          ENV["AZURE_SPEECH_KEY"].presence
        end

        def region
          ENV["AZURE_SPEECH_REGION"].presence
        end

        def configure?
          cle.present? && region.present?
        end

        # Jamais pendant la suite de tests : une spec distraite ne doit pas
        # pouvoir entamer l'allocation, ni dépendre du réseau pour passer.
        def disponible?
          configure? && !Rails.env.test?
        end

        def hote
          "#{region}.tts.speech.microsoft.com"
        end

        # Les voix françaises de la région — 31 au dernier comptage, toutes
        # servies au niveau F0, paliers « MAI-Voice » et « DragonHD » compris.
        # On ne trie pas : les voix neuronales classiques datent de 2019 et
        # sont devenues celles qu'on entend dans le navigateur, alors que les
        # récentes sonnent tout autrement. Les écarter reviendrait à cacher
        # précisément ce qu'on cherche. Cet appel-ci ne consomme aucun
        # caractère : il ne synthétise rien.
        def voix_disponibles
          corps = demander(Net::HTTP::Get.new("/cognitiveservices/voices/list"))
          JSON.parse(corps).
            select { |voix| voix["Locale"] == LOCALE && voix["VoiceType"].to_s.include?("Neural") }.
            pluck("ShortName").
            sort
        end

        def allocation_mensuelle
          ALLOCATION_MENSUELLE
        end

        # Sérialise les appels et les espace : le plafond F0 se compte par
        # fenêtre de 60 secondes, pas par requête.
        def attendre_la_cadence
          verrou.synchronize do
            maintenant = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            pause = @dernier_appel ? CADENCE_MINIMALE - (maintenant - @dernier_appel) : 0
            sleep(pause) if pause.positive?
            @dernier_appel = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end
        end

        def demander(requete, essai: 1)
          requete["Ocp-Apim-Subscription-Key"] = cle
          # Azure refuse les requêtes de synthèse sans User-Agent.
          requete["User-Agent"] = "Ensemble-Manipule"
          attendre_la_cadence
          traiter(executer(requete), requete, essai)
        end

        private

        def executer(requete)
          Net::HTTP.start(hote, 443,
                          use_ssl: true,
                          open_timeout: DELAI_OUVERTURE,
                          read_timeout: DELAI_LECTURE) do |http|
            http.request(requete)
          end
        rescue StandardError => e
          # Le message d'une erreur réseau ne contient jamais la clé ; celui
          # d'une exception inattendue, on ne sait pas. On ne relaie que la classe.
          raise Indisponible, "Azure injoignable (#{e.class})"
        end

        def traiter(reponse, requete, essai)
          case reponse
          when Net::HTTPSuccess then reponse.body
          when Net::HTTPTooManyRequests then reessayer(reponse, requete, essai)
          when Net::HTTPUnauthorized, Net::HTTPForbidden
            raise Indisponible,
                  "Azure refuse la clé (#{reponse.code}). Vérifie qu'elle vient d'une ressource " \
                  "Azure AI Speech et non d'une offre de la Place de marché, et que " \
                  "AZURE_SPEECH_REGION correspond bien à la région de cette ressource."
          else
            raise Indisponible, "Azure a répondu #{reponse.code} : #{reponse.body.to_s.truncate(200)}"
          end
        end

        def reessayer(reponse, requete, essai)
          raise Quota, "Azure limite les appels (429) et #{REESSAIS} tentatives n'ont pas suffi." if essai > REESSAIS

          sleep([reponse["Retry-After"].to_i, CADENCE_MINIMALE * essai].max)
          demander(requete, essai: essai + 1)
        end
      end

      def initialize(voix: nil, debit: nil)
        @voix = voix.presence || VOIX_DEFAUT
        @debit = debit || DEBIT_DEFAUT
      end

      def generer(texte)
        raise Indisponible, "Pas d'appel à Azure depuis la suite de tests." if Rails.env.test?
        raise Indisponible, "AZURE_SPEECH_KEY ou AZURE_SPEECH_REGION manque." unless self.class.configure?

        octets = self.class.demander(requete(ssml(texte)))
        raise Indisponible, "La synthèse n'a rien produit" if octets.blank?

        Rendu.new(octets:, content_type: CONTENT_TYPE, voix: @voix)
      end

      private

      def requete(corps)
        requete = Net::HTTP::Post.new("/cognitiveservices/v1")
        requete["Content-Type"] = "application/ssml+xml"
        requete["X-Microsoft-OutputFormat"] = FORMAT
        requete.body = corps
        requete
      end

      # L'énoncé vient de l'enseignante : il est échappé avant d'entrer dans le
      # XML, sans quoi une esperluette suffirait à casser la requête. Les
      # silences sont posés après, pour que leurs balises survivent.
      def ssml(texte)
        <<~XML.strip
          <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="#{LOCALE}">
            <voice name="#{@voix}">#{prosodie(ponctuer(CGI.escapeHTML(texte.to_s)))}</voice>
          </speak>
        XML
      end

      def prosodie(contenu)
        return contenu if @debit.to_i.zero?

        %(<prosody rate="#{@debit}%">#{contenu}</prosody>)
      end

      # Un silence après chaque phrase : c'est ce que l'enseignante demande, et
      # ça ne s'obtient pas en baissant le débit.
      def ponctuer(texte)
        texte.gsub(/([.!?…])\s+/, %(\\1 <break time="#{SILENCE_ENTRE_PHRASES_MS}ms"/> ))
      end
    end
  end
end
