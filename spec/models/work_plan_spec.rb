require "rails_helper"
RSpec.describe WorkPlan, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    User.destroy_all
    @work_plan1 = create(:work_plan)
  end

  it " is valid with valid attributes" do
    expect(@work_plan1).to be_valid
  end

  it " can have many work_plan_domains attached" do
    work_plan_domain1 = create(:work_plan_domain, work_plan: @work_plan1)
    work_plan_domain2 = create(:work_plan_domain, work_plan: @work_plan1)
    expect(@work_plan1.work_plan_domains.count).to eq(2)
  end

    it " can have  2 work_plan_skill attached to on work_plan_domain" do
    work_plan_domain1 = create(:work_plan_domain, work_plan: @work_plan1)
    skill1 = create(:skill, grade: @work_plan1.grade, domain:work_plan_domain1.domain, level: work_plan_domain1.level)
    skill2 = create(:skill, grade: @work_plan1.grade, domain:work_plan_domain1.domain, level: work_plan_domain1.level)
    create(:work_plan_skill, work_plan_domain: work_plan_domain1, skill: skill1)
    create(:work_plan_skill, work_plan_domain: work_plan_domain1, skill: skill2)
     expect(@work_plan1.work_plan_domains.last.work_plan_skills.count).to eq(2)
  end
end
