# frozen_string_literal: true

namespace :manipule do
  desc "Génère l'audio manquant ou périmé (VOIX= DEBIT= SKILL= PLAFOND= MANIPULE_TTS=azure|systeme)"
  task audio: :environment do
    # En développement, ActiveRecord écrit chaque requête sur la sortie
    # standard : quinze morceaux produisent deux cents lignes de SQL, où la
    # progression et le décompte des caractères deviennent introuvables.
    ActiveRecord::Base.logger = nil

    moteur = Manipule::Synthese.moteur
    abort "Moteur #{moteur.name.demodulize} indisponible ici." unless Manipule::Synthese.disponible?

    voix = ENV["VOIX"].presence
    puts "Moteur #{moteur.name.demodulize}, voix #{voix || moteur::VOIX_DEFAUT}."
    generation = Manipule::GenerationAudio.new(
      voix:, debit: ENV["DEBIT"].presence&.to_i, skill_id: ENV["SKILL"].presence,
      plafond: ENV.fetch("PLAFOND", Manipule::GenerationAudio::PLAFOND_CARACTERES).to_i,
      trace: -> { print "." }
    ).executer!
    puts
    puts generation.resume
  end

  # Liste les voix et les fait parler d'un coup : un nom de voix ne dit rien,
  # et les quelque mille caractères que ça consomme chez Azure pèsent 0,2 %
  # d'une allocation mensuelle.
  desc "Fabrique un échantillon de chaque voix française, pour choisir à l'oreille"
  task echantillons: :environment do
    ActiveRecord::Base.logger = nil
    abort "Moteur indisponible ici." unless Manipule::Synthese.disponible?

    dossier = Rails.root.join("tmp/manipule_voix")
    Manipule::Synthese.echantillons(Manipule::Synthese::PHRASE_TEMOIN, dossier).
      each { |voix, chemin| puts "  #{voix.ljust(32)} → #{chemin.basename}" }
    puts "Écoute : open #{dossier}"
  end
end
