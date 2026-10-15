# frozen_string_literal: true

require "rails_helper"

# Un domaine sans ceinture, sur la fiche mobile de l'élève. Il ouvre les
# compétences de la ceinture blanche.
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
  end

  it "ouvre la validation de la ceinture blanche, dans la modale" do
    lien = rendu.at_css("a")

    expect(lien["href"]).to eq("/mobile/students/#{eleve.id}/domains/#{domaine.id}/validation/edit")
    expect(lien["data-turbo-frame"]).to eq("general_modal")
    expect(lien["id"]).to eq("mobile_ceinture_#{eleve.id}_#{domaine.id}")
    expect(lien.at_css("i.domain_special_star")).to be_nil
  end

  it "marque d'une étoile un domaine spécial, qui ouvre la même validation" do
    domaine.update!(special: true)

    lien = rendu.at_css("a")

    expect(lien["href"]).to eq("/mobile/students/#{eleve.id}/domains/#{domaine.id}/validation/edit")
    expect(lien.at_css("i.domain_special_star")).to be_present
  end
end
