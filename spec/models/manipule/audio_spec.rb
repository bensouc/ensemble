# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::Audio do
  let(:probleme) { create(:manipule_problem) }

  def rendu(octets = "des octets")
    Manipule::Synthese::Rendu.new(octets:, content_type: "audio/mp4", voix: "Thomas")
  end

  def poser(texte)
    described_class.poser!(readable: probleme, role: "enonce", texte:, rendu: rendu)
  end

  it "garde le texte réellement dit, et sa taille" do
    audio = poser("Il y a 15 pommes.")

    expect(audio.texte_source).to eq("Il y a 15 pommes.")
    expect(audio.octets).to eq("des octets".bytesize)
  end

  # Si l'enseignante corrige un énoncé, l'audio dit encore l'ancienne version.
  # Sans ce contrôle, l'élève entendrait autre chose que ce qu'il lit.
  it "se sait périmé quand le texte a changé" do
    audio = poser("Il y a 15 pommes.")

    expect(audio.perime?("Il y a 15 pommes.")).to be false
    expect(audio.perime?("Il y a 12 pommes.")).to be true
  end

  it "remplace le morceau au lieu d'en empiler un second" do
    poser("Première version.")
    poser("Deuxième version.")

    expect(described_class.where(readable: probleme, role: "enonce").count).to eq(1)
    expect(described_class.last.texte_source).to eq("Deuxième version.")
  end

  it "n'accepte qu'un rôle connu" do
    audio = described_class.new(readable: probleme, role: "refrain", texte_source: "x", data: "y")

    expect(audio).not_to be_valid
  end
end
