# frozen_string_literal: true

require "rails_helper"

# Le plan de travail d'un élève se gère — consulter, modifier, supprimer,
# évaluer, y ajouter ou en retirer des compétences — par qui suit l'élève : les
# profs de sa classe, ceux du partage, les admins. Les policies demandaient
# seulement d'être de la même école que l'auteur du plan : n'importe quel
# collègue intervenait sur les élèves d'une classe qu'il n'a pas.
RSpec.describe "Droits sur les plans de travail", type: :request do
  let(:ecole) { create(:school) }
  let(:enseignant) { create(:user, school: ecole, admin: false) }
  let(:niveau) { create(:grade, school: ecole, name: "CE1", grade_level: "CE1") }
  let(:classe) { create(:classroom, user: enseignant, grade: niveau) }
  let(:eleve) { create(:student, classroom: classe) }
  let(:domaine) { create(:domain, grade: niveau, name: "Numération", position: 1) }
  let(:competence) { create(:skill, school: ecole, domain: domaine, level: 1) }
  let!(:plan) { create(:work_plan, user: enseignant, grade: niveau, student: eleve, name: "Semaine 3") }
  let!(:domaine_du_plan) { create(:work_plan_domain, work_plan: plan, domain: domaine, level: 1) }
  let!(:competence_du_plan) do
    create(:work_plan_skill, work_plan_domain: domaine_du_plan, skill: competence, kind: "ceinture")
  end

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }

  context "pour un collègue de l'école à qui la classe n'est pas partagée" do
    before { sign_in create(:user, school: ecole, admin: false) }

    it "n'ouvre ni le plan ni son évaluation" do
      get work_plan_path(plan)
      expect(response).to have_http_status(:redirect)

      get evaluation_path(plan)
      expect(response).to have_http_status(:redirect)
    end

    it "ne renomme pas le plan et ne le supprime pas" do
      patch work_plan_path(plan), params: { work_plan: { name: "Piraté", student_id: eleve.id } }
      expect(plan.reload.name).to eq("Semaine 3")

      expect { delete work_plan_path(plan) }.not_to change(WorkPlan, :count)
    end

    it "n'évalue pas l'élève" do
      patch work_plan_skill_eval_update_path(competence_du_plan), params: { status: "completed" }

      expect(competence_du_plan.reload.status).to eq("new")
    end

    it "n'ajoute ni ne retire de compétence ou de domaine" do
      expect do
        post work_plan_domain_work_plan_skills_path(domaine_du_plan),
             params: { skill: competence.id, kind: "ceinture" }, headers: turbo_headers
      end.not_to change(WorkPlanSkill, :count)

      expect { delete work_plan_skill_path(competence_du_plan), headers: turbo_headers }.
        not_to change(WorkPlanSkill, :count)
      expect { delete work_plan_domain_path(domaine_du_plan), headers: turbo_headers }.
        not_to change(WorkPlanDomain, :count)
    end
  end

  # Un plan sans élève n'appartient qu'à son auteur. L'ajout d'un domaine se
  # vérifiait par la règle de CRÉATION, qui accepte tout plan sans élève : un
  # enseignant de n'importe quelle école garnissait le plan d'un autre.
  it "ne laisse pas garnir le plan sans élève d'un autre enseignant" do
    modele = create(:work_plan, user: enseignant, grade: niveau, student: nil)
    sign_in create(:user, admin: false)

    expect do
      post work_plan_work_plan_domains_path(modele),
           params: { work_plan: { work_plan_domain: { domain: domaine.id, level: 1 } }, kind: "ceinture" }
    end.not_to change(WorkPlanDomain, :count)
  end

  # Réattribuer son plan, c'est le donner à un autre élève : un élève qu'on
  # suit, comme à la création.
  it "ne réattribue pas un plan à l'élève d'une classe qu'on n'a pas" do
    eleve_ailleurs = create(:student, classroom: create(:classroom, grade: niveau))
    sign_in enseignant

    patch work_plan_path(plan), params: { work_plan: { name: "Semaine 3", student_id: eleve_ailleurs.id } }

    expect(plan.reload.student).to eq(eleve)
  end

  context "pour un collègue avec qui la classe est partagée" do
    before do
      collegue = create(:user, school: ecole, admin: false)
      create(:shared_classroom, user: collegue, classroom: classe)
      sign_in collegue
    end

    it "consulte, renomme et évalue le plan" do
      get work_plan_path(plan)
      expect(response).to have_http_status(:ok)

      get evaluation_path(plan)
      expect(response).to have_http_status(:ok)

      patch work_plan_path(plan), params: { work_plan: { name: "Semaine 4", student_id: eleve.id } }
      expect(plan.reload.name).to eq("Semaine 4")

      patch work_plan_skill_eval_update_path(competence_du_plan), params: { status: "completed" }
      expect(competence_du_plan.reload.status).to eq("completed")
    end

    it "retire une compétence du plan" do
      expect { delete work_plan_skill_path(competence_du_plan), headers: turbo_headers }.
        to change(WorkPlanSkill, :count).by(-1)
    end
  end

  context "pour un admin d'une autre école" do
    before { sign_in create(:user, admin: true) }

    it "consulte, renomme et évalue le plan" do
      get work_plan_path(plan)
      expect(response).to have_http_status(:ok)

      get evaluation_path(plan)
      expect(response).to have_http_status(:ok)

      patch work_plan_path(plan), params: { work_plan: { name: "Semaine 4", student_id: eleve.id } }
      expect(plan.reload.name).to eq("Semaine 4")

      patch work_plan_skill_eval_update_path(competence_du_plan), params: { status: "completed" }
      expect(competence_du_plan.reload.status).to eq("completed")
    end

    it "ajoute et retire compétences et domaines" do
      expect do
        post work_plan_domain_work_plan_skills_path(domaine_du_plan),
             params: { skill: competence.id, kind: "ceinture" }, headers: turbo_headers
      end.to change(WorkPlanSkill, :count).by(1)

      expect { delete work_plan_skill_path(competence_du_plan), headers: turbo_headers }.
        to change(WorkPlanSkill, :count).by(-1)
      expect { delete work_plan_domain_path(domaine_du_plan), headers: turbo_headers }.
        to change(WorkPlanDomain, :count).by(-1)
    end

    it "garnit le plan sans élève d'un enseignant et réattribue un plan" do
      modele = create(:work_plan, user: enseignant, grade: niveau, student: nil)
      expect do
        post work_plan_work_plan_domains_path(modele),
             params: { work_plan: { work_plan_domain: { domain: domaine.id, level: 1 } }, kind: "ceinture" }
      end.to change(WorkPlanDomain, :count).by(1)

      eleve_ailleurs = create(:student, classroom: create(:classroom, grade: niveau))
      patch work_plan_path(plan), params: { work_plan: { name: "Semaine 3", student_id: eleve_ailleurs.id } }
      expect(plan.reload.student).to eq(eleve_ailleurs)
    end
  end
end
