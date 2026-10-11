# frozen_string_literal: true

require "rails_helper"

# La liste des exercices a une seconde partie, celle des exercices de ceinture,
# sous le même filtre niveau / domaine / ceinture. Donner ou non un de ces
# exercices aux compétences posées « ceinture » se règle sur la classe.
RSpec.describe "Exercices de ceinture", type: :request do
  let(:school) { create(:school) }
  let(:enseignant) { create(:user, school:, admin: false) }
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
  let!(:classroom) { create(:classroom, user: enseignant, grade:) }
  let!(:domain) { create(:domain, grade:, position: 1, name: "Numération") }
  let!(:skill) { create(:skill, domain:, level: 1, school:) }

  before { sign_in enseignant }

  def index_filtre
    get challenges_path, params: { "/challenges": { grade: grade.id, domain: domain.id, level: 1 } }
  end

  it "range chaque exercice dans sa partie, et n'y mélange rien" do
    create(:challenge, skill:, user: enseignant, name: "Classique A")
    create(:challenge, skill:, user: enseignant, name: "Épreuve B", for_belt: true)

    index_filtre

    page = Nokogiri::HTML(response.body)
    classiques = page.at_css("#skills-challenge-list").text
    ceintures = page.at_css("#skills-belt-challenge-list").text
    expect(classiques).to include("Classique A")
    expect(classiques).not_to include("Épreuve B")
    expect(ceintures).to include("Épreuve B")
    expect(ceintures).not_to include("Classique A")
    expect(page.at_css("#for_belt_dossier_skill_#{skill.id}")).to be_present
  end

  it "ouvre le formulaire d'ajout d'un exercice de ceinture dans sa frame" do
    get new_challenge_path(skill: skill.id, for_belt: true)

    page = Nokogiri::HTML(response.body)
    expect(page.at_css("turbo-frame#for_belt_skill_#{skill.id}_new_challenge")).to be_present
    expect(page.at_css("input[name='challenge[for_belt]']")["value"]).to eq("true")
  end
end
