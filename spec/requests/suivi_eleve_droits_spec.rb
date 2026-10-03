# frozen_string_literal: true

require "rails_helper"

# Suivre un élève — voir ses ceintures et ses compétences acquises, lui valider
# une ceinture ou des compétences, préparer son plan — est réservé à qui voit sa
# classe : son enseignant, les collègues du partage, les admins. Même règle que
# la fiche de l'élève (`StudentPolicy`). Les ceintures, les modales et l'ajout de
# compétences validées sautaient l'autorisation : il suffisait de l'id d'un
# élève, de n'importe quelle école.
RSpec.describe "Droits sur le suivi d'un élève", type: :request do
  let(:ecole) { create(:school) }
  let(:enseignant) { create(:user, school: ecole, admin: false) }
  let(:niveau) { create(:grade, school: ecole, name: "CE1", grade_level: "CE1") }
  let(:classe) { create(:classroom, user: enseignant, grade: niveau) }
  let!(:eleve) { create(:student, classroom: classe, first_name: "Lina") }
  let(:domaine) { create(:domain, grade: niveau, name: "Numération", position: 1) }
  let(:competence) { create(:skill, school: ecole, domain: domaine, level: 1, name: "Compter jusqu'à 100") }
  let(:ceinture) do
    create(:belt, student: eleve, domain: domaine, level: 1, completed: true, validated_date: Date.current)
  end

  def acquise?(eleve, competence)
    Result.completed.exists?(student: eleve, skill: competence)
  end

  shared_examples "un enseignant qui ne suit pas l'élève" do
    it "ne voit pas ses ceintures" do
      get student_show_path(eleve, domaine, 1)
      expect(response).to have_http_status(:redirect)

      get belt_path(ceinture)
      expect(response).to have_http_status(:redirect)
    end

    it "ne lui valide pas de ceinture" do
      expect { post student_belts_path(eleve), params: { belt: { domain_id: domaine.id, level: 1 } } }.
        not_to change(Belt, :count)
    end

    it "n'ouvre pas ses compétences acquises ni la génération de son plan" do
      competence

      get student_display_skills_modal_path(eleve, domaine)
      expect(response).to have_http_status(:redirect)

      get student_auto_gen_modal_path(eleve)
      expect(response).to have_http_status(:redirect)

      get student_new_work_plan_modal_path(eleve)
      expect(response).not_to have_http_status(:ok)
    end
  end

  context "pour un enseignant d'une autre école" do
    let(:intrus) { create(:user, admin: false) }

    before { sign_in intrus }

    it_behaves_like "un enseignant qui ne suit pas l'élève"

    # Les compétences sont cherchées dans l'école de l'intrus, l'élève n'importe
    # où : il validait ses propres compétences à l'élève d'une autre école.
    it "ne lui valide pas de compétences" do
      son_niveau = create(:grade, school: intrus.school, name: "CE1", grade_level: "CE1")
      sa_competence = create(:skill, school: intrus.school, level: 1,
                                     domain: create(:domain, grade: son_niveau, name: "Numération"))

      post student_add_validated_wps_path(eleve), params: { new_wps: { skills: ["", sa_competence.id.to_s] } }

      expect(acquise?(eleve, sa_competence)).to be(false)
    end
  end

  context "pour un collègue de l'école à qui la classe n'est pas partagée" do
    before { sign_in create(:user, school: ecole, admin: false) }

    it_behaves_like "un enseignant qui ne suit pas l'élève"

    it "ne lui valide pas de compétences" do
      post student_add_validated_wps_path(eleve), params: { new_wps: { skills: ["", competence.id.to_s] } }

      expect(acquise?(eleve, competence)).to be(false)
    end
  end

  context "pour l'enseignant de la classe" do
    before { sign_in enseignant }

    it "voit ses ceintures et ses compétences acquises" do
      competence

      get student_show_path(eleve, domaine, 1)
      expect(response).to have_http_status(:ok)

      get belt_path(ceinture)
      expect(response).to have_http_status(:ok)

      get student_display_skills_modal_path(eleve, domaine)
      expect(response).to have_http_status(:ok)

      get student_auto_gen_modal_path(eleve)
      expect(response).to have_http_status(:ok)

      get student_new_work_plan_modal_path(eleve)
      expect(response).to have_http_status(:ok)
    end

    it "lui valide une ceinture et des compétences" do
      competence

      expect { post student_belts_path(eleve), params: { belt: { domain_id: domaine.id, level: 1 } } }.
        to change { Belt.completed.where(student: eleve).count }.by(1)

      post student_add_validated_wps_path(eleve), params: { new_wps: { skills: ["", competence.id.to_s] } }
      expect(acquise?(eleve, competence)).to be(true)
    end
  end

  context "pour un collègue avec qui la classe est partagée" do
    let(:collegue) { create(:user, school: ecole, admin: false) }

    before do
      create(:shared_classroom, user: collegue, classroom: classe)
      sign_in collegue
    end

    it "lui valide une ceinture" do
      expect { post student_belts_path(eleve), params: { belt: { domain_id: domaine.id, level: 1 } } }.
        to change { Belt.completed.where(student: eleve).count }.by(1)
    end

    # `BeltPolicy` cherchait le partage sur `student.shared_classrooms`, une
    # association qui n'existe pas : seul le propriétaire de la classe passait,
    # le collègue du partage tombait sur une erreur 500.
    it "modifie et supprime une ceinture" do
      get edit_belt_path(ceinture)
      expect(response).to have_http_status(:ok)

      expect { delete belt_path(ceinture) }.to change(Belt, :count).by(-1)
    end
  end
end
