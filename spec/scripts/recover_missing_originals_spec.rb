# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("scripts/recover_missing_originals")

# Le service de stockage est le service Disk du test : uploads, existence et
# suppressions sont donc réels. Seuls l'inventaire Cloudinary et le
# téléchargement du variant sont bouchonnés.
RSpec.describe MissingOriginalRecovery do
  let(:output) { StringIO.new }
  let(:image) { "contenu d'image factice" }

  # Un blob dont l'enregistrement existe mais dont le fichier a disparu.
  def orphan_blob(filename: "photo.png")
    ActiveStorage::Blob.create_before_direct_upload!(
      filename: filename, byte_size: 999, checksum: "ancien-checksum", content_type: "image/png"
    ).tap { |blob| blob.update_columns(metadata: { "identified" => true }) }
  end

  def entry_for(blob, width: 1024, height: 768)
    CloudinaryInventory::Entry.new(
      blob: blob, state: :recoverable,
      variants: [CloudinaryInventory::Variant.new(
        public_id: "variants/#{blob.key}/abc", url: "https://res.cloudinary.test/#{blob.key}",
        width: width, height: height, bytes: image.bytesize
      )]
    )
  end

  def stub_inventory(*entries)
    allow_any_instance_of(CloudinaryInventory).to receive(:by_state).with(:recoverable).and_return(entries)
  end

  def stub_download(body: image, code: "200")
    response = instance_double(Net::HTTPResponse, body: body, code: code)
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(code == "200")
    allow(Net::HTTP).to receive(:get_response).and_return(response)
  end

  before { stub_download }

  describe "simulation" do
    let!(:blob) { orphan_blob }

    before { stub_inventory(entry_for(blob)) }

    it "ne dépose aucun fichier" do
      described_class.new(dry_run: true, out: output).run

      expect(blob.service.exist?(blob.key)).to be(false)
    end

    it "annonce la définition qui serait récupérée" do
      described_class.new(dry_run: true, out: output).run

      expect(output.string).to include("1024×768", "1 original(aux) à récupérer")
    end
  end

  describe "application" do
    let!(:blob) { orphan_blob }

    before do
      stub_inventory(entry_for(blob))
      described_class.new(dry_run: false, confirm: 1, out: output).run
      blob.reload
    end

    it "dépose le variant à la key de l'original" do
      expect(blob.service.exist?(blob.key)).to be(true)
      expect(blob.service.download(blob.key)).to eq(image)
    end

    it "aligne les métadonnées sur le fichier réellement déposé" do
      expect(blob.byte_size).to eq(image.bytesize)
      expect(blob.checksum).to eq(Digest::MD5.base64digest(image))
      expect(blob.metadata).to include("width" => 1024, "height" => 768)
    end

    # Sans cette trace, rien ne distinguerait plus une image récupérée d'un
    # original authentique — or sa définition est plafonnée par le variant.
    it "garde trace de la provenance" do
      expect(blob.metadata["recovered_from_variant"]).to eq("variants/#{blob.key}/abc")
    end
  end

  describe "garde-fous" do
    let!(:blob) { orphan_blob }

    before { stub_inventory(entry_for(blob)) }

    it "refuse d'écrire sans confirmation du périmètre" do
      described_class.new(dry_run: false, out: output).run

      expect(blob.service.exist?(blob.key)).to be(false)
      expect(output.string).to include("Confirmation requise", "CONFIRM=1")
    end

    it "n'écrase jamais un original déjà présent" do
      blob.service.upload(blob.key, StringIO.new("original authentique"))

      described_class.new(dry_run: false, confirm: 1, out: output).run

      expect(blob.service.download(blob.key)).to eq("original authentique")
      expect(output.string).to include("un original existe déjà")
    end

    it "signale l'échec d'un téléchargement sans rien écrire" do
      stub_download(body: "", code: "404")

      described_class.new(dry_run: false, confirm: 1, out: output).run

      expect(blob.service.exist?(blob.key)).to be(false)
      expect(output.string).to include("HTTP 404")
    end

    # Chaque image est indépendante : un échec ne doit pas priver les autres.
    it "poursuit malgré l'échec d'une image" do
      failing, healthy = orphan_blob(filename: "ko.png"), orphan_blob(filename: "ok.png")
      stub_inventory(entry_for(failing), entry_for(healthy))
      allow(failing.service).to receive(:exist?).and_call_original
      allow(failing.service).to receive(:exist?).with(failing.key).and_raise(StandardError, "réseau")

      described_class.new(dry_run: false, confirm: 2, out: output).run

      expect(healthy.service.exist?(healthy.key)).to be(true)
      expect(output.string).to include("1 original(aux) restauré(s)", "1 échec(s)")
    end
  end

  describe "retour arrière" do
    let!(:blob) { orphan_blob }

    it "retire le fichier déposé et remet les métadonnées" do
      stub_inventory(entry_for(blob))
      FileUtils.rm_rf(described_class::DUMP_DIR)
      described_class.new(dry_run: false, confirm: 1, out: output).run
      dump = Dir[described_class::DUMP_DIR.join("*.json")].max_by { |f| File.mtime(f) }

      described_class.new(restore: dump, out: output).run

      expect(blob.service.exist?(blob.key)).to be(false)
      expect(blob.reload).to have_attributes(byte_size: 999, checksum: "ancien-checksum")
    end
  end
end
