# frozen_string_literal: true

require "rails_helper"

# Un plan de travail puise dans le référentiel de son école : ses niveaux, ses
# domaines, ses compétences, ses exercices. Chaque élément était pris dans la
# requête par son id, sans contrôle : un enseignant attachait à son propre plan
# le domaine, la compétence ou l'exercice d'une autre école — et lisait ensuite
# l'énoncé dans son plan.
RSpec.describe "Référentiel des plans de travail", type: :request do
  let(:ecole) { create(:school) }
  let(:niveau) { create(:grade, school: ecole, name: "CE1", grade_level: "CE1") }
  let(:domaine) { create(:domain, grade: niveau, name: "Numération", position: 1) }
  let(:competence) { create(:skill, school: ecole, domain: domaine, level: 1) }
  let(:exercice) { create(:challenge, skill: competence, name: "Les dizaines du voisin") }

  let(:enseignant) { create(:user, admin: false) }
  let(:son_niveau) { create(:grade, school: enseignant.school, name: "CE1", grade_level: "CE1") }
  let(:son_domaine) { create(:domain, grade: son_niveau, name: "Numération", position: 1) }
  let(:sa_competence) { create(:skill, school: enseignant.school, domain: son_domaine, level: 1) }
  let(:son_exercice) { create(:challenge, skill: sa_competence, user: enseignant, name: "Mes dizaines") }
  let(:son_eleve) { create(:student, classroom: create(:classroom, user: enseignant, grade: son_niveau)) }
  let(:son_plan) { create(:work_plan, user: enseignant, grade: son_niveau, student: son_eleve) }
  let(:son_domaine_du_plan) { create(:work_plan_domain, work_plan: son_plan, domain: son_domaine, level: 1) }
  let(:sa_competence_du_plan) do
    create(:work_plan_skill, work_plan_domain: son_domaine_du_plan, skill: sa_competence, kind: "exercice",
                             challenge: son_exercice)
  end

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }

  def ajouter_domaine(plan, domaine)
    post work_plan_work_plan_domains_path(plan),
         params: { work_plan: { work_plan_domain: { domain: domaine.id, level: 1 } }, kind: "ceinture" }
  end

  before { sign_in enseignant }

  it "ne crée pas de plan sur le niveau d'une autre école" do
    expect do
      post work_plans_path, params: { work_plan: { name: "Emprunt", grade_id: niveau.id,
                                                   start_date: Date.current, end_date: Date.current + 4 } }
    end.not_to change(WorkPlan, :count)
  end

  it "ne génère pas de plan sur le domaine d'une autre école" do
    competence

    post student_auto_new_wp_path(son_eleve), params: { student: { domains: ["", domaine.id.to_s] } }

    expect(WorkPlanDomain.where(domain: domaine)).to be_empty
  end

  it "n'ajoute pas à son plan le domaine d'une autre école" do
    competence

    expect { ajouter_domaine(son_plan, domaine) }.not_to change(WorkPlanDomain, :count)
  end

  it "n'ajoute pas à son plan la compétence d'une autre école" do
    expect do
      post work_plan_domain_work_plan_skills_path(son_domaine_du_plan),
           params: { skill: competence.id, kind: "ceinture" }, headers: turbo_headers
    end.not_to change(WorkPlanSkill, :count)
  end

  it "ne met pas dans son plan l'exercice d'une autre école" do
    patch work_plan_skill_path(sa_competence_du_plan), params: { work_plan_skill: { challenge_id: exercice.id } },
                                                       headers: turbo_headers
    expect(sa_competence_du_plan.reload.challenge).to eq(son_exercice)
  end

  it "puise dans le référentiel de son école" do
    sa_competence
    autre_exercice = create(:challenge, skill: sa_competence, user: enseignant, name: "Mes centaines")

    expect { ajouter_domaine(son_plan, son_domaine) }.to change(WorkPlanDomain, :count).by(1)

    patch work_plan_skill_path(sa_competence_du_plan), params: { work_plan_skill: { challenge_id: autre_exercice.id } },
                                                       headers: turbo_headers
    expect(sa_competence_du_plan.reload.challenge).to eq(autre_exercice)
  end
end
