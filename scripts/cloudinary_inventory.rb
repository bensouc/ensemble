# frozen_string_literal: true

# État des images d'exercices sur Cloudinary. STRICTEMENT EN LECTURE.
#
#   bin/rails runner scripts/cloudinary_inventory.rb
#
# Voir scripts/support/cloudinary_inventory.rb pour le détail du rangement et
# la mise en garde sur le compte partagé dev/prod.
require "json"
require_relative "support/cloudinary_inventory"

REPORT = Rails.root.join("tmp/cloudinary_inventory.json")

inventory = CloudinaryInventory.new
counts = inventory.counts

puts "=== ÉTAT DES ORIGINAUX ==="
puts format("  %-42s %s", "original présent", counts.fetch(:present, 0))
puts format("  %-42s %s", "original absent, variant récupérable", counts.fetch(:recoverable, 0))
puts format("  %-42s %s", "original absent, aucun variant (perdu)", counts.fetch(:lost, 0))

recoverable = inventory.by_state(:recoverable)
if recoverable.any?
  puts "\n=== récupérables, par année de dépôt ==="
  recoverable.group_by { |e| e.blob.created_at.year }.sort.each { |year, list| puts "  #{year} : #{list.size}" }

  puts "\n=== définition qu'on récupérerait ==="
  recoverable.map { |e| e.best_variant }.group_by { |v| "#{v.width}×#{v.height}" }
             .sort_by { |_, list| -list.size }.first(6)
             .each { |size, list| puts "  #{size.ljust(12)} #{list.size}" }

  puts "\n  échantillon :"
  recoverable.first(5).each do |entry|
    best = entry.best_variant
    puts "    ##{entry.blob.id} #{entry.blob.filename.to_s.truncate(34).ljust(36)} " \
         "#{entry.variants.size} variant(s), meilleur #{best.width}×#{best.height}"
  end
end

lost = inventory.by_state(:lost)
if lost.any?
  puts "\n=== PERDUS — ni original ni variant ==="
  lost.first(20).each { |e| puts "    ##{e.blob.id} #{e.blob.filename} (#{e.blob.created_at.to_date})" }
  puts "    …et #{lost.size - 20} autre(s)" if lost.size > 20
end

File.write(REPORT, JSON.pretty_generate(
                     "generated_at" => Time.current.iso8601,
                     "environment" => Rails.env,
                     "counts" => counts,
                     "recoverable" => recoverable.map(&:to_h),
                     "lost" => lost.map(&:to_h)
                   ))
puts "\nRapport écrit : #{REPORT}"
