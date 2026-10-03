# frozen_string_literal: true

# Fabrique d'avance les variantes d'images que les textes affichent.
#
# Avec le suivi des variantes (`track_variants`), Rails note en base chaque
# variante qu'il fabrique. Celles qui existaient avant sur Cloudinary ne sont
# notées nulle part : sans ce préchauffage, chaque image serait refabriquée au
# premier affichage, devant l'enseignant. À lancer une fois après la mise en
# service du suivi (bin/rails active_storage:prechauffer_variantes).
#
# Sans danger à relancer : une variante déjà suivie ne coûte qu'une lecture en
# base. Une image qui échoue est notée et n'arrête pas les autres.
class PrechauffageVariantes
  Echec = Struct.new(:blob_id, :taille, :message)

  attr_reader :fabriquees, :deja_pretes, :ignorees, :echecs

  def initialize(journal: $stdout)
    @journal = journal
    @fabriquees = 0
    @deja_pretes = 0
    @ignorees = 0
    @echecs = []
  end

  def call
    raise "Le suivi des variantes est coupé (config.active_storage.track_variants)" unless ActiveStorage.track_variants

    ActionText::RichText.where(id: textes_avec_images).find_each do |texte|
      besoins(texte.body).each { |blob, galerie| prechauffer(blob, galerie) }
    end
    self
  end

  private

  def textes_avec_images
    ActiveStorage::Attachment.where(record_type: "ActionText::RichText", name: "embeds").select(:record_id)
  end

  # Une image affichée seule prend la taille du texte ; dans une galerie, celle
  # de la galerie. La même image peut apparaître des deux façons.
  def besoins(contenu)
    toutes = contenu.attachments.map(&:attachable).grep(ActiveStorage::Blob)
    galerie = contenu.gallery_attachments.map(&:attachable).grep(ActiveStorage::Blob)
    seules = toutes.tally.filter_map { |blob, n| blob if n > galerie.count(blob) }

    seules.map { |blob| [blob, false] } + galerie.uniq.map { |blob| [blob, true] }
  end

  def prechauffer(blob, galerie)
    return @ignorees += 1 unless blob.variable?

    variante = VariantesImages.representation(blob, galerie:)
    return @deja_pretes += 1 if blob.variant_records.exists?(variation_digest: variante.variation.digest)

    fabriquer(variante)
  rescue StandardError => e
    @echecs << Echec.new(blob.id, galerie ? "galerie" : "texte", e.message.lines.first.to_s.strip)
  end

  def fabriquer(variante)
    variante.processed
    @fabriquees += 1
    @journal.puts "  #{@fabriquees} variantes fabriquées…" if (@fabriquees % 50).zero?
  end
end
