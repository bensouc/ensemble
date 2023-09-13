# frozen_string_literal: true

require "rails_helper"
RSpec.describe User, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    SchoolRole.destroy_all
    User.destroy_all
    @user1 = create(:user)
  end

  it "is valid with valid attributes" do
    expect(@user1).to be_valid
    # p @user1
  end

  it "has a unique email" do
    user2 = build(:user, email: @user1.email)
    expect(user2).to_not be_valid
  end

  it "is not valid without a password" do
    user2 = build(:user, password: nil)
    expect(user2).to_not be_valid
  end

  it "is not valid without a username" do
    user2 = build(:user, first_name: nil)
    expect(user2).to_not be_valid
  end

  it "is not valid without an email" do
    user2 = build(:user, email: nil)
    expect(user2).to_not be_valid
  end
end
