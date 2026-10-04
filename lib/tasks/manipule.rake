# frozen_string_literal: true

namespace :manipule do
  desc "Génère l'audio manquant ou périmé des problèmes (VOIX=Thomas DEBIT=150 SKILL=id)"
  task audio: :environment do
    abort "`say` est introuvable : cet adaptateur ne sert qu'en développement." unless Manipule::Synthese.disponible?

    voix = ENV.fetch("VOIX", Manipule::Synthese::VOIX_DEFAUT)
    generation = Manipule::GenerationAudio.new(
      voix:, debit: ENV.fetch("DEBIT", Manipule::Synthese::DEBIT_DEFAUT).to_i,
      skill_id: ENV["SKILL"].presence, trace: -> { print "." }
    ).executer!

    puts
    puts "Voix #{voix} — #{generation.faits} morceaux générés, #{generation.sautes} déjà à jour."
    puts "Total en base : #{generation.total_en_base} morceaux, #{generation.megaoctets_en_base} Mo."
  end

  desc "Fabrique un échantillon de chaque voix française, pour choisir à l'oreille"
  task echantillons: :environment do
    abort "`say` est introuvable." unless Manipule::Synthese.disponible?

    phrase = "Il y a quinze pommes sur le pommier. Sam cueille sept pommes. " \
             "Combien reste-t-il de pommes sur le pommier ?"
    dossier = Rails.root.join("tmp/manipule_voix")
    Manipule::Synthese.echantillons(phrase, dossier).each { |voix, chemin| puts "  #{voix.ljust(28)} → #{chemin.basename}" }

    puts
    puts "Écoute : open #{dossier}"
  end
end
