# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper do
  # Les URL des tutos sont la seule chose qui relie l'app au Notion, et elles
  # peuvent s'écrire de deux façons : avec le titre de la page en préfixe, ou
  # avec son seul identifiant. La première meurt au premier renommage, sans que
  # rien ne le signale — d'où cette forme unique, tenue ici.
  describe "les liens vers les tutos" do
    let(:identifiant_nu) { %r{\Ahttps://vroadstudio\.notion\.site/[0-9a-f]{32}\z} }

    it "s'écrivent tous avec l'identifiant nu de la page" do
      described_class::TUTO_LINKS.each do |ecran, url|
        expect(url).to match(identifiant_nu), "#{ecran} : #{url}"
      end
    end

    it "vaut aussi pour le sommaire" do
      expect(described_class::TUTO_SOMMAIRE).to match(identifiant_nu)
    end

    it "renvoient au sommaire depuis un écran sans tuto" do
      expect(helper.get_tuto_links("inconnu")).to eq(described_class::TUTO_SOMMAIRE)
    end

    it "renvoient au tuto de l'écran quand il en a un" do
      expect(helper.get_tuto_links("work_plans")).to eq(described_class::TUTO_LINKS["work_plans"])
    end
  end
end
