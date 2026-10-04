# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::Synthese do
  def avec(tts)
    ancien = ENV.fetch("MANIPULE_TTS", nil)
    ENV["MANIPULE_TTS"] = tts
    yield
  ensure
    ENV["MANIPULE_TTS"] = ancien
  end

  describe "le choix du moteur" do
    # En test, Azure se déclare indisponible quoi qu'il arrive : la suite ne
    # doit dépendre ni du réseau ni de ce qui traîne dans le .env de la machine.
    it "retombe sur la voix du système quand Azure n'est pas disponible" do
      expect(described_class.moteur).to eq(described_class::Systeme)
    end

    it "prend Azure dès qu'il est disponible" do
      allow(described_class::Azure).to receive(:disponible?).and_return(true)

      expect(described_class.moteur).to eq(described_class::Azure)
    end

    it "se laisse forcer sur la voix locale, pour itérer sans consommer" do
      allow(described_class::Azure).to receive(:disponible?).and_return(true)

      avec("systeme") { expect(described_class.moteur).to eq(described_class::Systeme) }
    end

    it "se laisse forcer sur Azure" do
      avec("azure") { expect(described_class.moteur).to eq(described_class::Azure) }
    end
  end

  describe "ce que le moteur dicte" do
    it "donne la voix par défaut du moteur courant" do
      expect(described_class.voix_defaut).to eq(described_class::Systeme::VOIX_DEFAUT)

      avec("azure") { expect(described_class.voix_defaut).to eq(described_class::Azure::VOIX_DEFAUT) }
    end

    # `GenerationAudio` compare cette voix à celle déjà en base pour savoir
    # s'il faut refaire un morceau : elle doit être celle réellement retenue,
    # pas celle qu'on a demandée.
    it "expose la voix retenue, et non celle demandée" do
      expect(described_class.new.voix).to eq(described_class::Systeme::VOIX_DEFAUT)
      expect(described_class.new(voix: "Audrey").voix).to eq("Audrey")
    end
  end
end
