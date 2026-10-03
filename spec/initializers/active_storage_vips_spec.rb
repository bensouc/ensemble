# frozen_string_literal: true

require "rails_helper"

# config/initializers/active_storage_vips.rb — GHSA-xr9x-r78c-5hrm.
RSpec.describe "libvips face aux images envoyées" do
  # Netpbm : un format que libvips lit sans dépendance extérieure, donc présent
  # partout, et qu'il classe parmi les non fiables.
  let(:ppm) { Rails.root.join("tmp/sonde_vips.ppm") }

  before { File.write(ppm, "P3\n1 1\n255\n0 0 0\n") }
  after { FileUtils.rm_f(ppm) }

  # Bloqué, le loader n'est même plus candidat : libvips ne reconnaît plus le
  # format, plutôt que de dire qu'il le refuse.
  it "refuse de lire un format que libvips juge non fiable" do
    expect { Vips::Image.new_from_file(ppm.to_s).avg }.
      to raise_error(Vips::Error, /not a known file format|blocked/)
  end

  # Témoin : sans le blocage, la même sonde se lit. Sans ce témoin, le refus
  # ci-dessus pourrait venir d'autre chose que de la protection.
  it "lirait ce même fichier sans la protection" do
    Vips.block_untrusted(false)
    expect(Vips::Image.new_from_file(ppm.to_s).width).to eq(1)
  ensure
    Vips.block_untrusted(true)
  end

  it "analyse toujours un PNG envoyé" do
    png = Vips::Image.black(3, 2).write_to_buffer(".png")
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(png), filename: "image.png")

    blob.analyze

    expect(blob.metadata).to include("width" => 3, "height" => 2)
  end

  it "ne propose plus de variante pour BMP, ICO et PSD" do
    expect(ActiveStorage.variable_content_types).
      not_to include("image/bmp", "image/vnd.microsoft.icon", "image/vnd.adobe.photoshop")
    expect(ActiveStorage.variable_content_types).to include("image/png", "image/jpeg")
  end
end
