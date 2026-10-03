# frozen_string_literal: true

require "rails_helper"

# Voir, ajouter, renommer, supprimer un élève : réservé à qui voit sa classe —
# son enseignant, les collègues du partage, les admins. Le contrôleur sautait
# l'autorisation : un enseignant d'une autre école pouvait supprimer un élève
# en donnant son id.
RSpec.describe "Droits sur les élèves", type: :request do
  let(:enseignant) { create(:user, admin: false) }
  let(:classe) { create(:classroom, user: enseignant) }
  let!(:eleve) { create(:student, classroom: classe, first_name: "Lina") }
  let(:intrus) { create(:user, admin: false) }

  context "pour un enseignant d'une autre école" do
    before { sign_in intrus }

    it "ne supprime pas l'élève" do
      expect { delete student_path(eleve) }.not_to change(Student, :count)
      expect(flash[:alert]).to be_present
    end

    it "ne le renomme pas" do
      patch student_path(eleve), params: { student: { first_name: "Intrus" } }

      expect(eleve.reload.first_name).to eq("Lina")
    end

    it "n'ajoute pas d'élève dans sa classe" do
      expect { post students_path, params: { student: { first_name: "Intrus", classroom: classe.id } } }.
        not_to change(Student, :count)
    end

    it "n'ouvre pas sa fiche" do
      get student_path(eleve)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
    end
  end

  it "laisse l'enseignant de la classe renommer et supprimer" do
    sign_in enseignant

    patch student_path(eleve), params: { student: { first_name: "Lina B." } }
    expect(eleve.reload.first_name).to eq("Lina B.")

    expect { delete student_path(eleve) }.to change(Student, :count).by(-1)
  end

  it "laisse un collègue du partage ajouter un élève" do
    collegue = create(:user, admin: false)
    create(:shared_classroom, user: collegue, classroom: classe)
    sign_in collegue

    expect { post students_path, params: { student: { first_name: "Noé", classroom: classe.id } } }.
      to change(Student, :count).by(1)
  end
end
