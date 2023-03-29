# frozen_string_literal: true

require "rails_helper"
RSpec.describe Belt, type: :model do

  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    User.destroy_all
    @belt1 = create(:belt)
  end

  it " is valid with valid attributes" do
    expect(@belt1).to be_valid
  end

  describe "#completed?" do
    it "returns true if Belt is completed" do
      belt1 = build(:belt, completed: true)
      expect(belt1.completed?).to eq(true)
    end
    it "returns false if Belt is not completed" do
      belt2 = build(:belt, completed: false)
      expect(belt2.completed?).to eq(false)
    end
  end

  
  # it " is valid with valid attributes" do
  #   expect(@work_plan1).to be_valid
  # end
end
