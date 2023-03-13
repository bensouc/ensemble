require "rails_helper"
RSpec.describe Challenge, type: :model do
  before(:all) do
    Challenge.destroy_all
    User.destroy_all
    @challenge1 = create(:challenge)
  end

  it " is valid with valid attributes" do
    expect(@challenge1).to be_valid
  end

  it "has a unique name for the same Skill" do
    challenge2 = build(:challenge, name: @challenge1.name, skill: @challenge1.skill)
    expect(challenge2).to_not be_valid
  end

end
