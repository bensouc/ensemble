# frozen_string_literal: true

require "rails_helper"
RSpec.describe WorkPlan, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    SchoolRole.destroy_all
    User.destroy_all
    @user1 = create(:user)
    @work_plan1 = create(:work_plan)
  end
  it " is valid with valid attributes" do
    expect(@work_plan1).to be_valid
  end

  it " can have many work_plan_domains attached" do
    create(:work_plan_domain, work_plan: @work_plan1)
    create(:work_plan_domain, work_plan: @work_plan1)
    expect(@work_plan1.work_plan_domains.count).to eq(2)
  end


end
