# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChallengesHelper, type: :helper do
  # Ces classes vivaient en dur, écrites deux fois dans le filtre de l'index.
  # Les tenir en un seul endroit évite qu'une troisième copie diverge.
  describe "#classe_ceinture" do
    it "donne à chaque ceinture sa couleur" do
      expect(helper.classe_ceinture(1)).to eq("--bgc-blanc")
      expect(helper.classe_ceinture(3)).to eq("--bgc-orange")
    end

    # Sur une ceinture foncée, un texte sombre disparaît.
    it "éclaircit le texte sur les ceintures foncées" do
      expect(helper.classe_ceinture(7)).to include("--blanc")
    end

    it "couvre les sept ceintures" do
      expect((1..7).map { |n| helper.classe_ceinture(n) }).to all(be_present)
    end

    # Un niveau hors bornes ne doit pas produire la classe de la dernière
    # ceinture par le jeu des index négatifs de Ruby.
    it "ne rend rien pour un niveau hors bornes" do
      expect(helper.classe_ceinture(0)).to eq("")
      expect(helper.classe_ceinture(99)).to eq("")
    end
  end

  describe "#options_ceintures" do
    it "porte la couleur sur chaque option" do
      expect(helper.options_ceintures(1)).to include('class="--bgc-jaune"')
    end

    it "marque la ceinture courante" do
      expect(helper.options_ceintures(4)).to match(/<option[^>]*selected="selected"[^>]*value="4"/)
    end

    # « Ceinture verte », pas « Vert » : les libellés viennent de
    # `Belt::BELT_COLORS`, accordés au féminin.
    it "accorde les libellés au féminin" do
      expect(helper.options_ceintures(1)).to include("Verte", "Bleue")
    end
  end
end
