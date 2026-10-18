# frozen_string_literal: true

require "rails_helper"

# Le gabarit du PDF de la fiche de ceinture, sans lancer Chrome : ce qui est
# imprimé, et ce qui ne l'est pas.
RSpec.describe "pdfs/belt_sheet", type: :view do
  let(:school) { create(:school) }
  let(:user) { create(:user, school:) }
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
  let(:student) { create(:student, classroom: create(:classroom, user:, grade:), first_name: "abel") }
  let(:numeration) { create(:domain, grade:, name: "Numération", position: 1, special: false) }
  let(:geometrie) { create(:domain, grade:, name: "Géométrie", position: 2, special: true) }
  let(:sheet) { BeltSheet.create!(student:, user:) }

  def rendu
    render template: "pdfs/belt_sheet", locals: { belt_sheet: sheet, blocs: sheet.reload.ordered_domains }
    Nokogiri::HTML(rendered)
  end

  it "imprime le cartouche, une bande par compétence et son énoncé" do
    skill = create(:skill, domain: numeration, level: 6, school:, name: "Les nombres jusqu'à 1000", symbol: "◼")
    epreuve = create(:challenge, skill:, user:, for_belt: true, content: "<div>Écris en chiffres</div>")
    sheet.belt_sheet_domains.create!(domain: numeration, level: 6).belt_sheet_skills.create!(skill:, challenge: epreuve)

    page = rendu

    cartouche = page.at_css(".cartouche").text.squish
    expect(cartouche).to include("Numération", "Ceinture marron", "Abel", "Date")
    expect(page.at_css(".bande").text).to include("Les nombres jusqu'à 1000")
    expect(page.at_css(".bande img")).to be_present
    expect(page.at_css(".enonce").text).to include("Écris en chiffres")
  end

  it "dit qu'un exercice reste à définir, plutôt que d'imprimer une case vide" do
    skill = create(:skill, domain: numeration, level: 1, school:, name: "Compter")
    sheet.belt_sheet_domains.create!(domain: numeration, level: 1).belt_sheet_skills.create!(skill:)

    expect(rendu.at_css(".enonce").text).to include("Exercice de ceinture à définir")
  end

  it "laisse le prénom à écrire sur une fiche non assignée" do
    skill = create(:skill, domain: numeration, level: 1, school:, name: "Compter")
    fiche = BeltSheet.generer!(grade, numeration, 1, user)

    render template: "pdfs/belt_sheet", locals: { belt_sheet: fiche, blocs: fiche.reload.ordered_domains }
    page = Nokogiri::HTML(rendered)

    expect(page.at_css(".cartouche .eleve").text.squish).to start_with("Prénom : Date")
    expect(page.at_css(".bande").text).to include(skill.name)
  end

  it "n'imprime pas un bloc sans compétence" do
    sheet.belt_sheet_domains.create!(domain: geometrie, level: 1)

    expect(rendu.css(".bloc")).to be_empty
  end
end
