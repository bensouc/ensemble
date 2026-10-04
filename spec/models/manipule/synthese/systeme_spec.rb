# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::Synthese::Systeme do
  describe "la ponctuation lue" do
    # Un silence après chaque phrase : c'est ce que l'enseignante demande, et ça
    # ne s'obtient pas en baissant le débit.
    it "glisse un silence après chaque fin de phrase" do
      texte = described_class.new.send(:ponctuer, "Il y a 15 pommes. Sam en cueille 7.")

      expect(texte).to include("15 pommes. [[slnc 600]] Sam")
    end

    it "ne touche pas à une phrase unique" do
      texte = described_class.new.send(:ponctuer, "Combien reste-t-il de pommes ?")

      expect(texte).not_to include("slnc")
    end

    it "traite aussi les questions et les exclamations" do
      texte = described_class.new.send(:ponctuer, "Combien ? Dis-moi !")

      expect(texte.scan("slnc").size).to eq(1)
    end
  end

  it "refuse de produire quoi que ce soit là où `say` n'existe pas" do
    allow(described_class).to receive(:disponible?).and_return(false)

    expect { described_class.new.generer("Bonjour") }.to raise_error(Manipule::Synthese::Indisponible)
  end
end
