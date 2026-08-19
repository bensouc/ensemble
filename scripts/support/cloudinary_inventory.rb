# frozen_string_literal: true

# Inventaire des images d'exercices présentes sur Cloudinary.
#
# STRICTEMENT EN LECTURE : seul appel distant, Cloudinary::Api.resources (GET).
#
# ⚠ dev et prod partagent le compte `bensoucdev`. L'état des FICHIERS est donc
# réel quel que soit l'environnement ; en revanche la liste des blobs vient de
# la base LOCALE, et celle de dev est une copie datée. L'inventaire qui fait foi
# est celui lancé en production.
#
# Rangement (cf. docs/recuperation_images.md) : `folder:` étant commenté dans
# storage.yml, l'original est déposé À LA RACINE sous la key du blob, et les
# variants dans `variants/<key>/<digest>`.
require "set"

class CloudinaryInventory
  Variant = Struct.new(:public_id, :url, :width, :height, :bytes, keyword_init: true) do
    def pixels = width.to_i * height.to_i
    def to_h = { public_id: public_id, url: url, width: width, height: height, bytes: bytes }
  end

  Entry = Struct.new(:blob, :state, :variants, keyword_init: true) do
    # Le variant de meilleure définition : on récupère la moins mauvaise image
    # possible, l'original étant définitivement perdu.
    def best_variant = variants.max_by(&:pixels)

    def to_h
      { blob_id: blob.id, key: blob.key, filename: blob.filename.to_s,
        created_at: blob.created_at.to_date.to_s, byte_size: blob.byte_size,
        variants: variants.map(&:to_h) }
    end
  end

  def initialize(out: $stdout)
    @out = out
  end

  def entries
    @entries ||= build_entries
  end

  def by_state(state) = entries.select { |entry| entry.state == state }

  def counts = entries.group_by(&:state).transform_values(&:size)

  private

  def build_entries
    remote = fetch_remote
    say "\n#{remote[:all].size} ressources : #{remote[:all].size - remote[:variants].values.sum(&:size)} " \
        "à la racine, #{remote[:variants].values.sum(&:size)} variants sur #{remote[:variants].size} key(s)."

    blobs = image_blobs
    say "#{blobs.count} image(s) d'exercice référencée(s) en base.\n"

    blobs.map do |blob|
      variants = remote[:variants].fetch(blob.key, [])
      state = if remote[:all].include?(blob.key) then :present
              elsif variants.any? then :recoverable
              else :lost
              end
      Entry.new(blob: blob, state: state, variants: variants)
    end
  end

  # Un listing paginé plutôt qu'un Api.resource par blob : 7 appels au lieu de
  # 800, et on reste loin des limites de l'API.
  def fetch_remote
    all = Set.new
    variants = Hash.new { |hash, key| hash[key] = [] }
    cursor = nil
    page = 0

    say "Listing des ressources Cloudinary (lecture seule)…"
    loop do
      response = Cloudinary::Api.resources(type: "upload", max_results: 500, next_cursor: cursor)
      response["resources"].each do |resource|
        id = resource["public_id"]
        all << id
        next unless id.start_with?("variants/")

        variants[id.split("/")[1]] << Variant.new(
          public_id: id, url: resource["secure_url"],
          width: resource["width"], height: resource["height"], bytes: resource["bytes"]
        )
      end
      page += 1
      say "  page #{page} — #{all.size} ressources cumulées"
      cursor = response["next_cursor"]
      break unless cursor
    end

    { all: all, variants: variants }
  end

  def image_blobs
    ActiveStorage::Blob
      .joins(:attachments)
      .where(active_storage_attachments: { record_type: "ActionText::RichText", name: "embeds" })
      .where("active_storage_blobs.content_type LIKE ?", "image/%")
      .distinct
  end

  def say(message) = @out.puts(message)
end
