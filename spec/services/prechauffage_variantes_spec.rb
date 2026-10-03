# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrechauffageVariantes do
  subject(:prechauffage) { described_class.new(journal: StringIO.new) }

  def image(nom)
    png = Vips::Image.black(1600, 1200).write_to_buffer(".png")
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new(png), filename: nom, content_type: "image/png")
  end

  def piece_jointe(blob, galerie: false)
    presentation = galerie ? ' presentation="gallery"' : ""
    %(<action-text-attachment sgid="#{blob.attachable_sgid}"#{presentation}></action-text-attachment>)
  end

  def suivie?(blob, galerie: false)
    digest = VariantesImages.representation(blob, galerie:).variation.digest
    blob.variant_records.exists?(variation_digest: digest)
  end

  let(:seule) { image("seule.png") }
  let(:gauche) { image("gauche.png") }
  let(:droite) { image("droite.png") }

  before do
    create(:challenge, content: "<div>Consigne</div>#{piece_jointe(seule)}" \
                                "<div>#{piece_jointe(gauche, galerie: true)}#{piece_jointe(droite, galerie: true)}</div>")
  end

  it "fabrique chaque image à la taille où le texte l'affiche" do
    prechauffage.call

    expect(prechauffage.fabriquees).to eq(3)
    expect(suivie?(seule)).to be(true)
    expect(suivie?(gauche, galerie: true)).to be(true)
    expect(suivie?(droite, galerie: true)).to be(true)
    expect(suivie?(gauche)).to be(false)
  end

  it "ne refait rien quand on la relance" do
    prechauffage.call

    relance = described_class.new(journal: StringIO.new).call

    expect(relance.fabriquees).to eq(0)
    expect(relance.deja_pretes).to eq(3)
    expect(ActiveStorage::VariantRecord.count).to eq(3)
  end

  # La vue et la tâche partagent leurs tailles : la variante préchauffée est
  # celle que la page demandait déjà, au même digest qu'avant le changement.
  it "fabrique les tailles que la vue demandait" do
    expect(VariantesImages.representation(seule).variation.digest).
      to eq(seule.representation(resize_to_limit: [1024, 768]).variation.digest)
    expect(VariantesImages.representation(seule, galerie: true).variation.digest).
      to eq(seule.representation(resize_to_limit: [800, 600]).variation.digest)
  end

  it "laisse de côté ce qui n'est pas une image" do
    texte = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("bonjour"), filename: "note.txt",
                                                   content_type: "text/plain")
    create(:challenge, content: piece_jointe(texte))

    prechauffage.call

    expect(prechauffage.ignorees).to eq(1)
  end

  it "note l'image dont l'original manque, et continue" do
    seule.service.delete(seule.key)

    prechauffage.call

    expect(prechauffage.echecs.map(&:blob_id)).to eq([seule.id])
    expect(prechauffage.fabriquees).to eq(2)
  end
end
