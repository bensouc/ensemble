# frozen_string_literal: true

module Manipule
  class Synthese
    # La voix du système, par `say` — présent sur macOS, nulle part ailleurs.
    #
    # Sert à écouter et à trancher en développement, quand on reformule un
    # énoncé trois fois de suite et qu'il n'y a aucune raison d'entamer
    # l'allocation distante pour ça.
    class Systeme
      VOIX_DEFAUT = "Thomas"
      DEBIT_DEFAUT = 150 # mots par minute ; la voix du système en fait ~175
      SILENCE_ENTRE_PHRASES_MS = 600
      CONTENT_TYPE = "audio/mp4"

      attr_reader :voix

      def self.disponible?
        File.executable?("/usr/bin/say")
      end

      def self.configure?
        disponible?
      end

      def self.voix_disponibles
        `say -v "?"`.lines.grep(/fr_FR/).map { |ligne| ligne.split(/\s{2,}/).first.strip }
      end

      def initialize(voix: nil, debit: nil)
        @voix = voix.presence || VOIX_DEFAUT
        @debit = debit || DEBIT_DEFAUT
      end

      # Renvoie les octets d'un m4a, que tous les navigateurs savent lire.
      def generer(texte)
        raise Indisponible, "`say` n'est pas disponible sur cette machine" unless self.class.disponible?

        sortie = Tempfile.new(["manipule", ".m4a"])
        begin
          executer(texte, sortie.path)
          octets = File.binread(sortie.path)
          raise Indisponible, "La synthèse n'a rien produit" if octets.empty?

          Rendu.new(octets:, content_type: CONTENT_TYPE, voix: @voix)
        ensure
          sortie.close
          sortie.unlink
        end
      end

      private

      # Forme tableau, jamais une chaîne de shell : le texte vient de
      # l'enseignante, et il n'a aucune raison de pouvoir exécuter quoi que ce soit.
      def executer(texte, chemin)
        ok = system("/usr/bin/say", "-v", @voix, "-r", @debit.to_s,
                    "-o", chemin, "--data-format=aac", ponctuer(texte),
                    out: File::NULL, err: File::NULL)
        raise Indisponible, "`say` a échoué" unless ok
      end

      # Un silence après chaque phrase : c'est ce que l'enseignante demande, et
      # ça ne s'obtient pas en baissant le débit.
      def ponctuer(texte)
        texte.to_s.gsub(/([.!?…])\s+/, "\\1 [[slnc #{SILENCE_ENTRE_PHRASES_MS}]] ")
      end
    end
  end
end
