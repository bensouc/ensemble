require "rails_helper"

RSpec.describe SchoolRole, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    Belt.destroy_all
    SchoolRole.destroy_all
    User.destroy_all
    Skill.destroy_all
    School.destroy_all
    @school_role = create(:school_role)
  end

  it " is valid with valid attributes" do
    expect(@school_role).to be_valid
  end
end
