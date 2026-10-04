# frozen_string_literal: true

require "rails_helper"

# Une ceinture obtenue, sur la fiche mobile de l'élève : sa couleur, sa date,
# son domaine. Un domaine spécial ouvre en plus la modale de ses compétences.
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
    expect(page.at_css("a")).to be_nil
  end

  it "écrit le domaine en clair sur les ceintures foncées" do
    ceinture.update!(level: 5)

    expect(rendu(ceinture, domaine).at_css("h6")["class"]).to eq("text-light")
  end

  it "ouvre la modale des compétences d'un domaine spécial, marqué d'une étoile" do
    domaine.update!(special: true)

    lien = rendu(ceinture, domaine).at_css("a")

    expect(lien["href"]).to eq("/students/#{eleve.id}/domains/#{domaine.id}/modal")
    expect(lien["data-turbo-frame"]).to eq("general_modal")
    expect(lien.at_css("i.domain_special_star")).to be_present
  end
end
