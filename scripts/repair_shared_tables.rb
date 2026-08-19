# frozen_string_literal: true

# Réparation des tableaux partagés entre plusieurs exercices.
#
#   bin/rails runner scripts/repair_shared_tables.rb                        # simulation
#   DRY_RUN=0 CONFIRM=<n> bin/rails runner scripts/repair_shared_tables.rb  # application
#   RESTORE=<fichier> bin/rails runner scripts/repair_shared_tables.rb      # retour arrière
#
# On écrit dans les données de production : six garde-fous, dans l'ordre.
#   1. simulation par défaut — il faut DRY_RUN=0 pour écrire ;
#   2. CONFIRM=<n> doit correspondre au nombre de copies annoncé par la
#      simulation, sinon on s'arrête : le périmètre a bougé entre-temps ;
#   3. refus de démarrer si les sgid ne se vérifient pas avec la clé de
#      l'environnement (les écrire ailleurs qu'en prod les rendrait perdus) ;
#   4. sauvegarde JSON des corps AVANT toute écriture, relue et vérifiée ;
#   5. tout se fait dans UNE transaction — la moindre anomalie annule tout ;
#   6. après chaque réécriture, on vérifie que le corps ne diffère QUE par le
#      sgid, et on relit depuis la base pour confirmer.
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

  # Erreur de vérification : annule la transaction, donc toutes les écritures.
  class VerificationError < StandardError; end

  IGNORED_ON_COPY = %w[id created_at updated_at].freeze

  def initialize(dry_run: true, restore: nil, confirm: nil, out: $stdout)
    @dry_run = dry_run
    @restore = restore
    @confirm = confirm
    @out = out
  end

  def run
    return restore! if @restore

    return unless signing_key_valid?

    plan = build_plan
    return say("Aucun tableau partagé. Rien à faire.") if plan.empty?

    print_plan(plan)
    return say("\n#{plan.size} copie(s) de tableau à créer.") if @dry_run
    return unless confirmed?(plan.size)

    dump_path = write_dump(plan)
    return unless dump_valid?(dump_path, plan)

    say "\nSauvegarde écrite : #{dump_path}"
    say "  ⚠ dans un conteneur, tmp/ disparaît au redéploiement — récupère ce fichier."

    created = []
    begin
      # Tout-ou-rien : une anomalie sur le dernier exercice annule les premiers.
      ActiveRecord::Base.transaction do
        plan.each { |reference| created << reassign(reference) }
      end
    rescue VerificationError => e
      say "\n⛔ ANNULÉ — aucune écriture conservée."
      say "   #{e.message}"
      return
    end

    record_created_tables(dump_path, created)
    say "\n#{created.size} copie(s) de tableau créées, vérifiées une à une."
    say "Retour arrière : RESTORE=#{dump_path} bin/rails runner scripts/repair_shared_tables.rb"
  end

  private

  def build_plan
    shared_groups.flat_map do |_table_id, references|
      references.sort_by { |r| [r.challenge.created_at, r.challenge.id] }.drop(1)
    end
  end

  def print_plan(plan)
    groups = shared_groups
    say "#{groups.size} tableau(x) partagé(s), #{groups.values.sum(&:size)} référence(s) au total."
    say @dry_run ? "\n-- SIMULATION (DRY_RUN=0 pour appliquer) --\n" : "\n-- APPLICATION --\n"

    groups.each do |table_id, references|
      keeper, *others = references.sort_by { |r| [r.challenge.created_at, r.challenge.id] }
      say "Table ##{table_id} — #{references.size} exercices"
      say "  garde  ##{keeper.challenge.id} #{keeper.challenge.name.truncate(50).inspect} (#{keeper.challenge.created_at.to_date})"
      others.each { |r| say "  copie  ##{r.challenge.id} #{r.challenge.name.truncate(50).inspect}" }
    end
  end

  # Le périmètre doit être celui qu'a vu l'opérateur pendant la simulation :
  # si la base a bougé entre les deux, on s'arrête.
  def confirmed?(count)
    return true if @confirm == count

    say "\n⛔ Confirmation requise : #{count} copie(s) à créer."
    say "   Relance avec CONFIRM=#{count} si ce nombre correspond à ta simulation."
    say "   (reçu : #{@confirm.inspect})" if @confirm
    false
  end


  # Les sgid sont signés avec le secret_key_base de l'environnement. En écrire
  # de nouveaux depuis un environnement dont la clé diffère produirait des
  # références irrécupérables. On refuse de démarrer dans ce cas.
  def signing_key_valid?
    sample = ActionText::RichText.where(record_type: "Challenge")
                                 .where("body LIKE ?", "%application/octet-stream%").first
    return true unless sample
    return true if sample.body.to_html.scan(/sgid="([^"]+)"/).flatten.any? { |sgid| table_for(sgid) }

    say "⛔ Les sgid présents en base ne se vérifient pas avec la clé de cet"
    say "   environnement : ce script doit tourner là où les exercices ont été"
    say "   créés (production). Écrire de nouveaux sgid ici les rendrait perdus."
    false
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

  # La sauvegarde est le seul retour arrière : on la relit depuis le disque
  # avant d'écrire quoi que ce soit.
  def dump_valid?(path, plan)
    payload = JSON.parse(File.read(path))
    expected = plan.to_h { |r| [r.rich_text.id, r.rich_text.body.to_html] }
    actual = payload["rich_texts"].to_h { |e| [e["rich_text_id"], e["body"]] }

    return true if actual == expected

    say "⛔ Sauvegarde illisible ou incomplète : on n'écrit rien."
    false
  rescue JSON::ParserError => e
    say "⛔ Sauvegarde illisible (#{e.message}) : on n'écrit rien."
    false
  end

  def record_created_tables(path, created)
    payload = JSON.parse(File.read(path))
    File.write(path, JSON.pretty_generate(payload.merge("created_table_ids" => created)))
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
  # Chaque étape est vérifiée : la moindre anomalie lève et annule la transaction.
  def reassign(reference)
    original = ActionText::Fragment.wrap(reference.rich_text.body.to_html).to_html
    copy = reference.table.duplicate
    verify_copy!(reference.table, copy)

    updated = ActionText::Fragment.wrap(original).update do |source|
      source.css(%(action-text-attachment[sgid="#{reference.sgid}"])).each do |node|
        node["sgid"] = copy.attachable_sgid
      end
    end.to_html

    verify_rewrite!(original, updated, reference.sgid, copy.attachable_sgid, reference)
    reference.rich_text.update_columns(body: updated, updated_at: Time.current)
    verify_persisted!(reference, copy)
    copy.id
  end

  def verify_copy!(source, copy)
    return if source.attributes.except(*IGNORED_ON_COPY) == copy.attributes.except(*IGNORED_ON_COPY)

    raise VerificationError, "la copie du tableau ##{source.id} diffère de l'original."
  end

  # Le corps réécrit ne doit différer QUE par le sgid : on remet l'ancien à la
  # place du nouveau et on doit retrouver l'original au caractère près.
  def verify_rewrite!(original, updated, old_sgid, new_sgid, reference)
    if updated == original
      raise VerificationError,
            "aucun sgid remplacé sur l'exercice ##{reference.challenge.id} — le sélecteur n'a rien trouvé."
    end

    return if updated.gsub(new_sgid, old_sgid) == original

    raise VerificationError,
          "le corps de l'exercice ##{reference.challenge.id} ne diffère pas seulement par le sgid."
  end

  # Relecture depuis la base, pas depuis l'objet en mémoire.
  #
  # On inspecte les sgid PORTÉS PAR LES PIÈCES JOINTES, pas le corps comme une
  # chaîne : jusqu'à la refonte de l'éditeur, le partial de tableau posait
  # `id="table-<sgid>"`, et ce HTML est figé dans l'attribut `content` de la
  # pièce jointe. Un `include?` sur le corps y retrouvait donc l'ancien sgid et
  # concluait à tort à un échec. Cet instantané est sans importance : ActionText
  # régénère le partial à chaque rendu.
  def attachment_sgids(rich_text)
    ActionText::Fragment.wrap(rich_text.body.to_html)
                        .find_all("action-text-attachment[sgid]")
                        .map { |node| node["sgid"] }
  end

  def verify_persisted!(reference, copy)
    sgids = attachment_sgids(ActionText::RichText.find(reference.rich_text.id))

    if sgids.include?(reference.sgid)
      raise VerificationError, "l'ancien sgid subsiste sur l'exercice ##{reference.challenge.id}."
    end

    return if sgids.filter_map { |sgid| table_for(sgid) }.map(&:id).include?(copy.id)

    raise VerificationError, "le tableau ##{copy.id} n'est pas résolvable depuis l'exercice ##{reference.challenge.id}."
  end

  def table_for(sgid)
    Table.from_attachable_sgid(sgid)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def say(message) = @out.puts(message)
end

if $PROGRAM_NAME.end_with?("runner")
  SharedTableRepair.new(
    dry_run: ENV["DRY_RUN"] != "0",
    restore: ENV["RESTORE"].presence,
    confirm: ENV["CONFIRM"].presence&.to_i
  ).run
end
