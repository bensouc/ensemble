# frozen_string_literal: true

require "rails_helper"

# Une ceinture obtenue, sur la fiche mobile de l'élève : sa couleur, sa date,
# son domaine. Elle ouvre les compétences de la ceinture suivante.
RSpec.describe Belts::BeltComponent, type: :component do
  let(:eleve) { create(:student) }
  let(:domaine) { create(:domain, name: "Numération", special: false) }
  let(:ceinture) do
    create(:belt, student: eleve, domain: domaine, level: 3, completed: true, validated_date: Date.new(2026, 9, 14))
  end

  def rendu(ceinture, domaine)
    render_inline(described_class.new(belt: ceinture, domain: domaine))
  end

  it "montre la couleur, la date et le domaine" do
    page = rendu(ceinture, domaine)

    expect(page.at_css(".mobile-belt-bar.belt-bg-3")).to be_present
    expect(page.at_css(".bar-style").text.squish).to eq("14 sept. 2026")
    expect(page.at_css("h6").text).to eq("Numération")
  end

  it "ouvre la validation de la ceinture suivante, dans la modale" do
    lien = rendu(ceinture, domaine).at_css("a")

    expect(lien["href"]).to eq("/mobile/students/#{eleve.id}/domains/#{domaine.id}/validation/edit")
    expect(lien["data-turbo-frame"]).to eq("general_modal")
    expect(lien["id"]).to eq("mobile_ceinture_#{eleve.id}_#{domaine.id}")
    expect(lien.at_css("i.domain_special_star")).to be_nil
  end

  it "le montre quand elle vient de tomber" do
    page = render_inline(described_class.new(belt: ceinture, domain: domaine, obtenue: true))

    expect(page.at_css("a")["class"].split).to include("--obtenue")
  end

  it "écrit le domaine en clair sur les ceintures foncées" do
    ceinture.update!(level: 5)

    expect(rendu(ceinture, domaine).at_css("h6")["class"]).to eq("text-light")
  end

  it "marque d'une étoile un domaine spécial, qui ouvre la même validation" do
    domaine.update!(special: true)

    lien = rendu(ceinture, domaine).at_css("a")

    expect(lien["href"]).to eq("/mobile/students/#{eleve.id}/domains/#{domaine.id}/validation/edit")
    expect(lien.at_css("i.domain_special_star")).to be_present
  end
end
