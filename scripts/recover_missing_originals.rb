# frozen_string_literal: true

# Récupération des originaux d'images disparus de Cloudinary.
#
#   bin/rails runner scripts/recover_missing_originals.rb                   # simulation
#   LIMIT=3 DRY_RUN=0 CONFIRM=3 bin/rails runner …                          # premier lot prudent
#   DRY_RUN=0 CONFIRM=<n> bin/rails runner …                                # tout le reste
#   RESTORE=<fichier> bin/rails runner …                                    # retour arrière
#
# Un nettoyage manuel de la Media Library a supprimé les originaux — déposés à
# la racine sous des noms aléatoires — en épargnant le dossier `variants/`.
# Rails ne servant les images que via un variant, et ne sachant qu'un variant
# existe que par sa propre table `active_storage_variant_records` (106 lignes
# pour 802 images), il retélécharge l'original la plupart du temps : d'où les
# images cassées.
#
# On ré-uploade donc le meilleur variant survivant à la key de l'original.
#
# ⚠ CE QU'ON RÉCUPÈRE N'EST PAS L'ORIGINAL. Un variant est un dérivé borné à
# 1024×768 et ré-encodé : la définition d'origine est perdue pour de bon. On
# échange une image cassée contre une image correcte mais moins définie.
#
# L'opération est ADDITIVE : on écrit là où il n'y a rien. Un original présent
# n'est jamais écrasé — c'est vérifié avant chaque écriture. Chaque image est
# traitée indépendamment ; s'arrêter en cours de route laisse donc un état
# cohérent, simplement partiel.
require "json"
require "digest"
require "net/http"
require_relative "support/cloudinary_inventory"

class MissingOriginalRecovery
  class RecoveryError < StandardError; end

  DUMP_DIR = Rails.root.join("tmp/recover_missing_originals")

  def initialize(dry_run: true, confirm: nil, limit: nil, restore: nil, out: $stdout)
    @dry_run = dry_run
    @confirm = confirm
    @limit = limit
    @restore = restore
    @out = out
  end

  def run
    return restore! if @restore

    targets = CloudinaryInventory.new(out: @out).by_state(:recoverable)
    targets = targets.first(@limit) if @limit
    return say("Aucun original à récupérer.") if targets.empty?

    announce(targets)
    return if @dry_run
    return unless confirmed?(targets.size)

    dump_path = write_dump(targets)
    say "\nSauvegarde écrite : #{dump_path}"
    say "  ⚠ dans un conteneur, tmp/ disparaît au redéploiement — récupère ce fichier."
    say ""

    done, failed = [], []
    targets.each_with_index do |entry, index|
      say format("  [%3d/%d] #%-6s %s", index + 1, targets.size, entry.blob.id,
                 entry.blob.filename.to_s.truncate(40))
      begin
        done << recover(entry)
      rescue RecoveryError, StandardError => e
        failed << [entry, e.message]
        say "           ⛔ #{e.message}"
      end
    end

    record_outcome(dump_path, done)
    say "\n#{done.size} original(aux) restauré(s)#{", #{failed.size} échec(s)" if failed.any?}."
    failed.each { |entry, message| say "  ##{entry.blob.id} : #{message}" }
    say "Retour arrière : RESTORE=#{dump_path} bin/rails runner scripts/recover_missing_originals.rb"
  end

  private

  def announce(targets)
    say "#{targets.size} original(aux) à récupérer#{" (limité à #{@limit})" if @limit}."
    say @dry_run ? "\n-- SIMULATION (DRY_RUN=0 pour appliquer) --\n" : "\n-- APPLICATION --\n"
    return unless @dry_run

    targets.first(15).each do |entry|
      best = entry.best_variant
      say format("  #%-6s %-40s %s×%s  (%s ko)", entry.blob.id,
                 entry.blob.filename.to_s.truncate(38), best.width, best.height, best.bytes.to_i / 1024)
    end
    say "  …et #{targets.size - 15} autre(s)" if targets.size > 15
    say "\n#{targets.size} original(aux) à récupérer."
  end

  def confirmed?(count)
    return true if @confirm == count

    say "\n⛔ Confirmation requise : #{count} original(aux) à récupérer."
    say "   Relance avec CONFIRM=#{count} si ce nombre correspond à ta simulation."
    false
  end

  # Le fichier d'origine étant perdu, la sauvegarde ne peut pas le restituer :
  # elle garde les métadonnées de la base et le variant employé, ce qui permet
  # de défaire proprement l'opération (supprimer le fichier déposé, remettre les
  # métadonnées) si le résultat ne convient pas.
  def write_dump(targets)
    FileUtils.mkdir_p(DUMP_DIR)
    path = DUMP_DIR.join("#{Time.current.strftime('%Y%m%d-%H%M%S')}.json")
    File.write(path, JSON.pretty_generate(
                       "generated_at" => Time.current.iso8601,
                       "blobs" => targets.map do |entry|
                         entry.to_h.merge(
                           "previous" => {
                             "byte_size" => entry.blob.byte_size,
                             "checksum" => entry.blob.checksum,
                             "metadata" => entry.blob.metadata
                           }
                         )
                       end
                     ))
    path
  end

  def record_outcome(path, done)
    payload = JSON.parse(File.read(path))
    File.write(path, JSON.pretty_generate(payload.merge("restored_blob_ids" => done)))
  end

  def recover(entry)
    blob = entry.blob
    service = blob.service

    # Garde-fou : on n'écrit jamais par-dessus un original présent.
    raise RecoveryError, "un original existe déjà à cette key" if service.exist?(blob.key)

    variant = entry.best_variant
    data = download(variant.url)
    raise RecoveryError, "variant vide" if data.blank?

    service.upload(blob.key, StringIO.new(data), filename: blob.filename,
                                                 checksum: Digest::MD5.base64digest(data))

    raise RecoveryError, "le fichier déposé reste introuvable" unless service.exist?(blob.key)

    blob.update_columns(
      byte_size: data.bytesize,
      checksum: Digest::MD5.base64digest(data),
      metadata: blob.metadata.merge("width" => variant.width, "height" => variant.height,
                                    "recovered_from_variant" => variant.public_id)
    )
    say "           ✓ #{variant.width}×#{variant.height}, #{data.bytesize / 1024} ko"
    blob.id
  end

  def download(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    raise RecoveryError, "téléchargement du variant : HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def restore!
    payload = JSON.parse(File.read(@restore))
    ids = Array(payload["restored_blob_ids"])
    say "Sauvegarde du #{payload['generated_at']} — #{ids.size} image(s) à défaire."

    payload["blobs"].each do |entry|
      next unless ids.include?(entry["blob_id"])

      blob = ActiveStorage::Blob.find_by(id: entry["blob_id"])
      next say("  introuvable : blob ##{entry['blob_id']}") unless blob

      blob.service.delete(blob.key)
      blob.update_columns(entry["previous"].slice("byte_size", "checksum", "metadata").symbolize_keys)
      say "  défait : ##{blob.id} #{entry['filename']}"
    end

    say "\n#{ids.size} récupération(s) annulée(s)."
  end

  def say(message) = @out.puts(message)
end

if $PROGRAM_NAME.end_with?("recover_missing_originals.rb")
  MissingOriginalRecovery.new(
    dry_run: ENV["DRY_RUN"] != "0",
    confirm: ENV["CONFIRM"].presence&.to_i,
    limit: ENV["LIMIT"].presence&.to_i,
    restore: ENV["RESTORE"].presence
  ).run
end
