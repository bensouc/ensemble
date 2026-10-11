# frozen_string_literal: true

require "rails_helper"

# Le sous-menu de « Voir », dans la barre de gauche : ouvert tant qu'on est dans
# une de ses pages, l'entrée courante marquée ; replié ailleurs.
RSpec.describe "Barre de gauche : Voir", type: :request do
  let(:school) { create(:school) }
  let(:enseignant) { create(:user, school:, admin: false) }
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
  let!(:classroom) { create(:classroom, user: enseignant, grade:, belt_sheets: true) }
  # Sans domaine, /challenges ne sait pas quoi filtrer (bug à part).
  let!(:domain) { create(:domain, grade:, position: 1, name: "Numération", special: false) }

  before { sign_in enseignant }

  def sous_menu
    Nokogiri::HTML(response.body).at_css(".nav-left-sub-links")
  end

  def entree_courante
    sous_menu.at_css("a[aria-current=page] .sub-link--active")&.text
  end

  it "reste ouvert sur Plans de travail, et sur ses exercices" do
    get work_plans_path
    expect(sous_menu["class"]).not_to include("d-none")
    expect(entree_courante).to eq("Plans de travail")

    get challenges_path
    expect(entree_courante).to eq("Plans de travail")
  end

  it "reste ouvert sur Ceintures, et sur les exercices de ceinture" do
    get belt_sheets_path
    expect(entree_courante).to eq("Ceintures")

    get challenges_path(ceinture: 1)
    expect(entree_courante).to eq("Ceintures")
  end

  it "est replié hors de Voir" do
    get classrooms_path

    expect(sous_menu["class"]).to include("d-none")
    expect(entree_courante).to be_nil
  end
end
