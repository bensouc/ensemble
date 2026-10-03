# frozen_string_literal: true

namespace :active_storage do
  desc "Fabrique d'avance les variantes d'images des textes, une fois le suivi des variantes en service"
  task prechauffer_variantes: :environment do
    debut = Time.current
    puts "Préchauffage des variantes d'images…"
    bilan = PrechauffageVariantes.new.call

    puts "Terminé en #{(Time.current - debut).round} s : #{bilan.fabriquees} fabriquées, " \
         "#{bilan.deja_pretes} déjà prêtes, #{bilan.ignorees} ignorées (pas des images), " \
         "#{bilan.echecs.size} en échec."
    bilan.echecs.each { |e| puts "  blob ##{e.blob_id} (#{e.taille}) : #{e.message}" }
  end
end
