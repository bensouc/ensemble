# frozen_string_literal: true

require "rails_helper"

# Un domaine sans ceinture, sur la fiche mobile de l'élève. Un domaine spécial
# ouvre quand même la modale de ses compétences, déjà acquises ou non.
RSpec.describe Belts::NoBeltComponent, type: :component do
  let(:eleve) { create(:student) }
  let(:domaine) { create(:domain, name: "Géométrie", special: false) }

  def rendu
    render_inline(described_class.new(student: eleve, domain: domaine))
  end

  it "annonce l'absence de ceinture dans le domaine" do
    page = rendu

    expect(page.at_css(".mobile-belt-bar.belt-bg-1 .bar-style").text.strip).to eq("Aucune Ceinture")
    expect(page.at_css("h6").text).to eq("Géométrie")
    expect(page.at_css("a")).to be_nil
  end

  it "ouvre la modale des compétences d'un domaine spécial, marqué d'une étoile" do
    domaine.update!(special: true)

    lien = rendu.at_css("a")

    expect(lien["href"]).to eq("/students/#{eleve.id}/domains/#{domaine.id}/modal")
    expect(lien["data-turbo-frame"]).to eq("general_modal")
    expect(lien.at_css("i.domain_special_star")).to be_present
  end
end
