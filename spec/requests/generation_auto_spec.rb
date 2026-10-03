# frozen_string_literal: true

require "rails_helper"

# La modale de génération laisse décocher tous les domaines. Sans domaine, il
# n'y a rien à générer : l'enseignant revient sur la fiche de l'élève, prévenu,
# et aucun plan vide n'est enregistré.
RSpec.describe "Génération automatique d'un plan de travail", type: :request do
  let(:user) { create(:user) }
  let(:classroom) { create(:classroom, user:) }
  let(:student) { create(:student, classroom:) }

  before do
    create(:domain, grade: classroom.grade, position: 1, name: "Numération")
    sign_in user
  end

  it "sans aucun domaine coché, ne crée rien et revient sur la fiche de l'élève" do
    expect { post student_auto_new_wp_path(student), params: { "/students/#{student.id}" => { domains: [""] } } }.
      not_to change(WorkPlan, :count)

    expect(response).to redirect_to(student_path(student))
    expect(flash[:notice]).to eq("Vous n'avez pas sélectionné de domaine")
  end
end
