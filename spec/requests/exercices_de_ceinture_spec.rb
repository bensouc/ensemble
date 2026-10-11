# frozen_string_literal: true

require "rails_helper"

# Deux onglets dans la liste des exercices, sous le même filtre niveau / domaine
# / ceinture : les exercices, et ceux de ceinture. Le second n'existe que pour
# un enseignant dont une classe a ouvert les fiches de ceinture.
RSpec.describe "Exercices de ceinture", type: :request do
  let(:school) { create(:school) }
  let(:enseignant) { create(:user, school:, admin: false) }
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
  let!(:classroom) { create(:classroom, user: enseignant, grade:, belt_sheets: true) }
  let!(:domain) { create(:domain, grade:, position: 1, name: "Numération") }
  let!(:skill) { create(:skill, domain:, level: 1, school:) }

  before { sign_in enseignant }

  def index_filtre(**extra)
    get challenges_path, params: { "/challenges": { grade: grade.id, domain: domain.id, level: 1 } }.merge(extra)
  end

  def liste
    Nokogiri::HTML(response.body).at_css("#skills-challenge-list").text
  end

  it "montre chaque liste dans son onglet, sans les mélanger" do
    create(:challenge, skill:, user: enseignant, name: "Classique A")
    create(:challenge, skill:, user: enseignant, name: "Épreuve B", for_belt: true)

    index_filtre
    expect(liste).to include("Classique A")
    expect(liste).not_to include("Épreuve B")

    index_filtre(ceinture: 1)
    expect(liste).to include("Épreuve B")
    expect(liste).not_to include("Classique A")
    expect(Nokogiri::HTML(response.body).at_css("#for_belt_dossier_skill_#{skill.id}")).to be_present
    # Le filtre garde l'onglet.
    expect(Nokogiri::HTML(response.body).at_css("#domainForm input[name=ceinture]")).to be_present
  end

  it "ne montre ni l'onglet ni la liste de ceinture sans classe aux fiches de ceinture" do
    classroom.update!(belt_sheets: false)
    create(:challenge, skill:, user: enseignant, name: "Épreuve B", for_belt: true)

    index_filtre(ceinture: 1)

    expect(response.body).not_to include("Exercices de ceinture")
    expect(liste).not_to include("Épreuve B")
  end

  it "ouvre le formulaire d'ajout d'un exercice de ceinture dans sa frame" do
    get new_challenge_path(skill: skill.id, for_belt: true)

    page = Nokogiri::HTML(response.body)
    expect(page.at_css("turbo-frame#for_belt_skill_#{skill.id}_new_challenge")).to be_present
    expect(page.at_css("input[name='challenge[for_belt]']")["value"]).to eq("true")
  end
end
