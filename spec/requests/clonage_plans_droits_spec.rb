# frozen_string_literal: true

require "rails_helper"

# Cloner un plan de travail en fait une copie pour soi, pour des élèves, ou pour
# un collègue (partage). L'action sautait l'autorisation : on copiait le plan de
# n'importe quelle école, on en déposait un chez n'importe quel compte — message
# compris — et on en distribuait aux élèves de n'importe quelle classe.
RSpec.describe "Droits sur le clonage des plans de travail", type: :request do
  let(:ecole) { create(:school) }
  let(:enseignant) { create(:user, school: ecole, admin: false) }
  let(:niveau) { create(:grade, school: ecole, name: "CE1", grade_level: "CE1") }
  let(:classe) { create(:classroom, user: enseignant, grade: niveau) }
  let!(:eleve) { create(:student, classroom: classe) }
  let!(:plan) { create(:work_plan, user: enseignant, grade: niveau, name: "Semaine 3") }
  # Le message qui annonce un partage est signé par un admin (`SharingMessages`).
  let!(:admin) { create(:user, admin: true) }

  let(:intrus) { create(:user, admin: false) }
  let(:plan_intrus) do
    create(:work_plan, user: intrus, grade: create(:grade, school: intrus.school, name: "CE1", grade_level: "CE1"))
  end

  def assigner(plan, eleves)
    post work_plan_clone_path(plan), params: { "/work_plans/#{plan.id}" => { students: ["", "-12"] + eleves.map { |e| e.id.to_s } } }
  end

  def partager(plan, avec:)
    post work_plan_clone_path(plan), params: { work_plan: { shared_user_id: avec.id } }
  end

  context "pour un enseignant d'une autre école" do
    before { sign_in intrus }

    it "ne copie pas le plan" do
      expect { post work_plan_clone_path(plan) }.not_to change(WorkPlan, :count)
    end

    it "ne dépose pas son plan chez un enseignant d'une autre école" do
      expect { partager(plan_intrus, avec: enseignant) }.not_to change(enseignant.work_plans, :count)
    end

    it "ne distribue pas son plan aux élèves d'une autre école" do
      expect { assigner(plan_intrus, [eleve]) }.not_to change(eleve.work_plans, :count)
    end
  end

  # Distribuer un plan, c'est créer un plan pour chaque élève : la règle de la
  # création (`WorkPlanPolicy#create?`), soit les élèves de ses classes et des
  # classes partagées.
  it "ne laisse pas un collègue de l'école distribuer un plan aux élèves d'une classe qu'il n'a pas" do
    collegue = create(:user, school: ecole, admin: false)
    son_plan = create(:work_plan, user: collegue, grade: niveau)
    sign_in collegue

    expect { assigner(son_plan, [eleve]) }.not_to change(eleve.work_plans, :count)
  end

  context "pour l'enseignant du plan" do
    before { sign_in enseignant }

    it "en fait une copie sans élève" do
      expect { post work_plan_clone_path(plan) }.
        to change { WorkPlan.where(user: enseignant, student: nil).count }.by(1)
    end

    it "le distribue à ses élèves" do
      autre_eleve = create(:student, classroom: classe)

      expect { assigner(plan, [eleve, autre_eleve]) }.
        to change { WorkPlan.where(student: [eleve, autre_eleve]).count }.by(2)
    end

    it "le partage avec un collègue de son école" do
      collegue = create(:user, school: ecole, admin: false)

      expect { partager(plan, avec: collegue) }.to change(collegue.work_plans, :count).by(1)
      expect(collegue.work_plans.last.shared_user).to eq(enseignant)
    end
  end
end
