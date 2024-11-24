# frozen_string_literal: true

require "rails_helper"
RSpec.describe Skill, type: :model do
  before(:all) do
    Skill.destroy_all
    @skill1 = create(:skill)
  end

  it "is valid with valid attributes" do
    expect(@skill1).to be_valid
    # p @skill1
  end

  it "is not valid without a level" do
    skill2 = build(:skill, level: nil)
    expect(skill2).to_not be_valid
  end

  it "is not valid without a level from the list" do
    skill2 = build(:skill, level: [0, (8..20).to_a.sample].sample)
    expect(skill2).to_not be_valid
  end

  it "is not valid without a symbol from the list" do
    skill2 = build(:skill, symbol: "⬤⬤")
    expect(skill2).to_not be_valid
  end

end
