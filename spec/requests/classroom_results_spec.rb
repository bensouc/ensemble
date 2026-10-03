# frozen_string_literal: true

require "rails_helper"

# Aucune spec n'ouvrait cette page : la montée en Rails 7.2 l'a cassée sans
# qu'un seul test rougisse (Classroom#completed_results_by_domain).
RSpec.describe "Résultats d'une classe", type: :request do
  let(:enseignant) { create(:user) }
  let(:classroom) { create(:classroom, user: enseignant) }

  before do
    domaine = create(:domain, grade: classroom.grade, position: 1)
    competence = create(:skill, domain: domaine)
    eleve = create(:student, classroom:)
    create(:result, student: eleve, skill: competence, status: "completed", kind: "ceinture")
    sign_in enseignant
  end

  it "s'affiche" do
    get results_classroom_path(classroom)

    expect(response).to have_http_status(:ok)
  end
end
