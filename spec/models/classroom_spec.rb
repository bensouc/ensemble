require "rails_helper"
RSpec.describe Classroom, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    User.destroy_all
    @classroom1 = create(:classroom)
  end

  it " is valid with valid attributes" do
    expect(@classroom1).to be_valid
  end
end
