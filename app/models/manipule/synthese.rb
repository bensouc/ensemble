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
  # Cet adaptateur-ci s'appuie sur `say`, présent sur macOS : il sert à écouter
  # et à trancher en développement. Une voix neuronale distante prendra le
  # relais pour la production, où `say` n'existe pas — seul ce fichier changera.
  class Synthese
    VOIX_DEFAUT = "Thomas"
    DEBIT_DEFAUT = 150 # mots par minute ; la voix du système en fait ~175
    SILENCE_ENTRE_PHRASES_MS = 600
    CONTENT_TYPE = "audio/mp4"

    class Indisponible < StandardError; end

    # Ce que rend une synthèse : les octets et de quoi savoir ce qui les a
    # produits. Les faire voyager ensemble évite de les perdre en route.
    Rendu = Struct.new(:octets, :content_type, :voix, keyword_init: true)

    def self.disponible?
      File.executable?("/usr/bin/say")
    end

    # Un échantillon par voix française du système, pour trancher à l'oreille
    # plutôt que sur le nom.
    def self.echantillons(phrase, dossier)
      FileUtils.mkdir_p(dossier)
      voix_du_systeme.map do |voix|
        chemin = Pathname(dossier).join("#{voix.gsub(/\W+/, '_')}.m4a")
        File.binwrite(chemin, new(voix:).generer(phrase).octets)
        [voix, chemin]
      end
    end

    def self.voix_du_systeme
      `say -v "?"`.lines.grep(/fr_FR/).map { |ligne| ligne.split(/\s{2,}/).first.strip }
    end

    def initialize(voix: VOIX_DEFAUT, debit: DEBIT_DEFAUT)
      @voix = voix
      @debit = debit
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
