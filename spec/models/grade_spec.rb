require 'rails_helper'

RSpec.describe Grade, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    SchoolRole.destroy_all
    User.destroy_all
    @school = create(:school)
    @grade = create(:grade, school: @school)
  end

  it " is valid with valid attributes" do
    expect(@grade).to be_valid
  end
end
