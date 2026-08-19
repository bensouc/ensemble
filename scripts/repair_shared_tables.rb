# frozen_string_literal: true

# Réparation des tableaux partagés entre plusieurs exercices.
#
#   bin/rails runner scripts/repair_shared_tables.rb            # simulation
#   DRY_RUN=0 bin/rails runner scripts/repair_shared_tables.rb  # application
#   RESTORE=<fichier> bin/rails runner scripts/repair_shared_tables.rb
#
# Jusqu'au correctif de Challenge#new_clone, cloner un exercice recopiait son
# corps verbatim : les deux exercices pointaient sur le MÊME enregistrement
# Table. Éditer une cellule depuis l'un modifiait silencieusement les autres.
#
# Ce script donne son propre tableau à chaque exercice. L'exercice le PLUS
# ANCIEN conserve l'enregistrement d'origine — c'est lui qui a été cloné.
#
# Idempotent : une fois réparé, plus aucun tableau n'est partagé, une seconde
# exécution ne trouve rien.
require "json"

class SharedTableRepair
  Reference = Struct.new(:rich_text, :challenge, :table, :sgid)

  DUMP_DIR = Rails.root.join("tmp/repair_shared_tables")

  def initialize(dry_run: true, restore: nil, out: $stdout)
    @dry_run = dry_run
    @restore = restore
    @out = out
  end

  def run
    return restore! if @restore

    ensure_signing_key!

    groups = shared_groups
    if groups.empty?
      say "Aucun tableau partagé. Rien à faire."
      return
    end

    say "#{groups.size} tableau(x) partagé(s), #{groups.values.sum(&:size)} référence(s) au total."
    say @dry_run ? "\n-- SIMULATION (DRY_RUN=0 pour appliquer) --\n" : "\n-- APPLICATION --\n"

    plan = groups.filter_map do |table_id, references|
      keeper, *others = references.sort_by { |r| [r.challenge.created_at, r.challenge.id] }
      say "Table ##{table_id} — #{references.size} exercices"
      say "  garde  ##{keeper.challenge.id} #{keeper.challenge.name.truncate(50).inspect} (#{keeper.challenge.created_at.to_date})"
      others.each { |r| say "  copie  ##{r.challenge.id} #{r.challenge.name.truncate(50).inspect}" }
      others.presence
    end.flatten

    if @dry_run
      say "\n#{plan.size} copie(s) de tableau à créer."
      return
    end

    dump_path = write_dump(plan)
    say "\nSauvegarde écrite : #{dump_path}"
    say "  ⚠ dans un conteneur, tmp/ disparaît au redéploiement — récupère ce fichier."

    created = plan.map { |reference| reassign(reference) }
    File.write(dump_path, JSON.pretty_generate(JSON.parse(File.read(dump_path)).merge("created_table_ids" => created)))

    say "\n#{created.size} copie(s) de tableau créées."
    say "Retour arrière : RESTORE=#{dump_path} bin/rails runner scripts/repair_shared_tables.rb"
  end

  private

  # Les sgid sont signés avec le secret_key_base de l'environnement. En écrire
  # de nouveaux depuis un environnement dont la clé diffère produirait des
  # références irrécupérables. On refuse de démarrer dans ce cas.
  def ensure_signing_key!
    sample = ActionText::RichText.where(record_type: "Challenge")
                                 .where("body LIKE ?", "%application/octet-stream%").first
    return unless sample
    return if sample.body.to_html.scan(/sgid="([^"]+)"/).flatten.any? { |s| table_for(s) }

    abort <<~MESSAGE
      Les sgid présents en base ne se vérifient pas avec la clé de cet
      environnement : ce script doit tourner là où les exercices ont été créés
      (production). Écrire de nouveaux sgid ici les rendrait irrécupérables.
    MESSAGE
  end

  def shared_groups
    references = Hash.new { |hash, key| hash[key] = [] }

    ActionText::RichText.where(record_type: "Challenge").includes(:record).find_each do |rich_text|
      rich_text.body.to_html.scan(/sgid="([^"]+)"/).flatten.uniq.each do |sgid|
        table = table_for(sgid)
        next unless table && rich_text.record

        references[table.id] << Reference.new(rich_text, rich_text.record, table, sgid)
      end
    end

    references.select { |_, refs| refs.size > 1 }
  end

  # Écrite AVANT toute modification : le script réécrit `body` via
  # update_columns, donc sans callback ni versionnement. C'est le seul retour
  # arrière possible.
  def write_dump(plan)
    FileUtils.mkdir_p(DUMP_DIR)
    path = DUMP_DIR.join("#{Time.current.strftime('%Y%m%d-%H%M%S')}.json")

    File.write(path, JSON.pretty_generate(
                       "generated_at" => Time.current.iso8601,
                       "rich_texts" => plan.map do |reference|
                         {
                           "rich_text_id" => reference.rich_text.id,
                           "challenge_id" => reference.challenge.id,
                           "challenge_name" => reference.challenge.name,
                           "body" => reference.rich_text.body.to_html
                         }
                       end
                     ))
    path
  end

  def restore!
    payload = JSON.parse(File.read(@restore))
    say "Sauvegarde du #{payload['generated_at']} — #{payload['rich_texts'].size} corps à restaurer."

    payload["rich_texts"].each do |entry|
      rich_text = ActionText::RichText.find_by(id: entry["rich_text_id"])
      next say("  introuvable : rich_text ##{entry['rich_text_id']}") unless rich_text

      rich_text.update_columns(body: entry["body"], updated_at: Time.current)
      say "  restauré : exercice ##{entry['challenge_id']} #{entry['challenge_name'].to_s.truncate(50).inspect}"
    end

    # Les copies créées par la passe ne sont plus référencées après restauration.
    created = Array(payload["created_table_ids"])
    Table.where(id: created).delete_all if created.any?
    say "\n#{payload['rich_texts'].size} corps restaurés, #{created.size} copie(s) de tableau supprimée(s)."
  end

  # Donne à cet exercice sa propre copie du tableau, et renvoie son id.
  def reassign(reference)
    copy = reference.table.duplicate

    updated = ActionText::Fragment.wrap(reference.rich_text.body.to_html).update do |source|
      source.css(%(action-text-attachment[sgid="#{reference.sgid}"])).each do |node|
        node["sgid"] = copy.attachable_sgid
      end
    end.to_html

    reference.rich_text.update_columns(body: updated, updated_at: Time.current)
    copy.id
  end

  def table_for(sgid)
    Table.from_attachable_sgid(sgid)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def say(message) = @out.puts(message)
end

if $PROGRAM_NAME.end_with?("runner")
  SharedTableRepair.new(dry_run: ENV["DRY_RUN"] != "0", restore: ENV["RESTORE"].presence).run
end
