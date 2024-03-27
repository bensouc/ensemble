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

  describe "#special?" do
    let(:student) { create(:student) }
    let(:grade) {create(:grade,grade_level: "CE1",name: "CE1")}
    let(:work_plan) { create(:work_plan, grade: , student:) }
    let(:domain) {create(:domain, grade:, special: true)}
    let(:work_plan_domain1) { create(:work_plan_domain, work_plan: work_plan, domain: ) }
    it "returns true if the work plan domain is a special domain" do
      expect(work_plan_domain1.special?).to be true
    end

  end
  describe "#all_domain_skills" do
    it 'TODO' do
    end
  end

end
