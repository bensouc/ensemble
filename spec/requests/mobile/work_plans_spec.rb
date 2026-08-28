# frozen_string_literal: true

require "rails_helper"

# L'écran d'évaluation est le cœur du front mobile : c'est le seul qui écrit, et
# celui où une régression fait perdre du travail à un enseignant sans qu'il s'en
# aperçoive. Ces specs le tiennent avant la refonte.
RSpec.describe "Mobile::WorkPlans", type: :request do
  let(:school) { create(:school) }
  let(:grade) { create(:grade, school:) }
  let(:teacher) { create(:user, admin: false, demo: false) }
  let(:classroom) { create(:classroom, user: teacher, grade:) }
  let(:student) { create(:student, classroom:, first_name: "leo") }
  let!(:work_plan) { create(:work_plan, user: teacher, grade:, student:, name: "Semaine 12") }

  before do
    school.add_teacher(teacher)
    teacher.reload
  end

  describe "GET /mobile/work_plans" do
    it "renvoie un visiteur non connecté vers la connexion" do
      get mobile_work_plans_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "liste ses plans de travail" do
      sign_in teacher

      get mobile_work_plans_path

      expect(response).to be_successful
      expect(response.body).to include("Semaine 12")
    end

    it "se rend dans le layout mobile" do
      sign_in teacher

      get mobile_work_plans_path

      expect(response).to render_template(layout: "layouts/mobile")
    end

    # Sans classe, l'écran explique quoi faire au lieu d'afficher une liste vide.
    it "guide l'enseignant qui n'a pas encore de classe" do
      sans_classe = create(:user, admin: false, demo: false)
      school.add_teacher(sans_classe)
      sign_in sans_classe

      get mobile_work_plans_path

      expect(response).to be_successful
      expect(response.body).to include("Vous n'avez pas de classe")
    end
  end

  describe "GET /mobile/work_plans/:id/evaluation" do
    it "refuse un visiteur non connecté" do
      get mobile_evaluation_path(work_plan)

      expect(response).to redirect_to(new_user_session_path)
    end

    # Le prénom sort brut ici (`leo`), alors que la fiche élève le capitalise.
    # Incohérence d'affichage à reprendre dans la refonte ; la spec constate
    # l'état actuel pour qu'un changement soit visible.
    it "ouvre l'évaluation du plan, avec l'élève et la période" do
      sign_in teacher

      get mobile_evaluation_path(work_plan)

      expect(response).to be_successful
      expect(response.body).to include("leo")
      expect(response.body).to include("Semaine 12")
    end

    it "refuse le plan de travail d'une autre école" do
      ailleurs = create(:work_plan, user: create(:user, admin: false), grade: create(:grade, school: create(:school)))
      sign_in teacher

      get mobile_evaluation_path(ailleurs)

      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "GET /mobile/work_plans/:id/export" do
    # La route existe (`mobile_export_work_plan`) mais `Mobile::WorkPlansController`
    # n'a pas d'action `export` : elle ne peut que lever. Le lien d'export du
    # mobile pointe en réalité sur la route non-mobile.
    it "devrait exporter le plan en PDF" do
      pending "Mobile::WorkPlansController n'a pas d'action #export"
      sign_in teacher

      get mobile_export_work_plan_path(work_plan)

      expect(response).to be_successful
    end
  end
end
