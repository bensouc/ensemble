# all_domain_skills
# frozen_string_literal: true

require "rails_helper"
RSpec.describe WorkPlanDomain, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    SchoolRole.destroy_all
    User.destroy_all
    @work_plan1 = create(:work_plan)
    @work_plan_domain1 = create(:work_plan_domain, work_plan: @work_plan1)
  end

  it " is valid with valid attributes" do
    expect(@work_plan_domain1).to be_valid
  end

  describe "#specials?" do
    let(:student) { create(:student) }
    let(:grade) {create(:grade,grade_level: "CE1",name: "CE1")}
    let(:work_plan) { create(:work_plan, grade: , student:) }
    let(:work_plan_domain1) { create(:work_plan_domain, work_plan: work_plan, domain: ["Géométrie", "Grandeurs et Mesures"].sample) }
    it "returns true if the work plan domain is a special domain" do
      expect(work_plan_domain1.specials?).to be true
    end
    let(:gradeCM2) {create(:grade, grade_level: "CM2",name: "CM2")}
    let(:work_plan2) { create(:work_plan,grade: gradeCM2, student:) }
    let(:work_plan_domain2) { create(:work_plan_domain, work_plan: work_plan2, domain: ["Géométrie", "Grandeurs et Mesures"].sample) }
    it "returns false if grade is CM2" do
      expect(work_plan_domain2.specials?).to be false
    end
    let(:work_plan3) { create(:work_plan , student:) }
    let(:work_plan_domain3) {
      create(:work_plan_domain, work_plan: work_plan3, domain: ["Calcul", "Numération", "Opérations",
                                                                "Résolution des Problèmes", "Calligraphie", "Conjugaison",
                                                                "Poésie et Expression orale", "Production d’écrit", "Grammaire",
                                                                "Lecture", "Vocabulaire"].sample)
    }
    it "returns false if is not 'Géométrie OR Grandeurs et Mesures' AND NOT 'CM2' " do
      expect(work_plan_domain3.specials?).to be false
    end
  end
  describe "#all_domain_skills" do
    it 'TODO' do
    end
  end

end
