# frozen_string_literal: true

require "rails_helper"

# Sur mobile, toucher une ceinture dans la fiche d'un élève ouvre cette modale.
# Rails 7.2 l'avait cassée (colonne `results.skills` introuvable) sans qu'une
# spec rougisse : aucune ne l'ouvrait.
RSpec.describe "Compétences acquises d'un élève dans un domaine", type: :request do
  let(:enseignant) { create(:user) }
  let(:classroom) { create(:classroom, user: enseignant) }
  let(:eleve) { create(:student, classroom:) }
  # Noms explicites : la factory en tire un au hasard parmi neuf, et deux domaines
  # du même niveau ne peuvent pas le partager.
  let(:domaine) { create(:domain, grade: classroom.grade, position: 1, name: "Numération") }

  def acquerir(eleve, competence)
    Result.find_or_initialize_by(student: eleve, skill: competence).update!(status: "completed", kind: "ceinture")
  end

  before { sign_in enseignant }

  it "liste les compétences acquises par l'élève dans ce domaine, et elles seules" do
    acquerir(eleve, create(:skill, domain: domaine, name: "Compter jusqu'à 100"))
    acquerir(create(:student, classroom:), create(:skill, domain: domaine, name: "Acquise par un autre élève"))
    calcul = create(:domain, grade: classroom.grade, position: 2, name: "Calcul")
    acquerir(eleve, create(:skill, domain: calcul, name: "Autre domaine"))

    get student_display_skills_modal_path(eleve, domaine)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Compter jusqu&#39;à 100")
    expect(response.body).not_to include("Acquise par un autre élève")
    expect(response.body).not_to include("Autre domaine")
  end
end
