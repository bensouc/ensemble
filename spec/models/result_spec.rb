require "rails_helper"

RSpec.describe Result, type: :model do
  before(:all) do
    Result.destroy_all
    # @result1 = create(:result)
    # @result = create(:result, status: "completed", kind: "ceinture")
    @domain = create(:domain)
    @skill1 = create(:skill, domain: @domain, level: 1)
    @skill2 = create(:skill, domain: @domain, level: 1)
  end

  describe "scopes" do
    it "has a scope for 'completed' results" do
      expect(Result.completed).to eq(Result.where(status: "completed", kind: "ceinture"))
    end
  end
  describe "#belt_validated?" do
    it "returns true for results with status 'completed' & ceinture as kind" do
      result = create(:result, status: "completed", kind: "ceinture")
      expect(result.belt_validated?).to eq(true)
    end
    it "returns false for results with any status other than 'completed' & belt as kind" do
      result = create(:result, kind: "exercice")
      expect(result.belt_validated?).to eq(false)
      result = create(:result, kind: "exercice", status: "completed")
      expect(result.belt_validated?).to eq(false)
    end
  end

  describe "#challenge_validated?" do
    it "returns true for results with status 'completed' & exercice as kind" do
      result = create(:result, status: "completed", kind: "exercice")
      expect(result.challenge_validated?).to eq(true)
    end
    it "returns false for results with  any status other  'completed' & 'exercice' as kind" do
      result = create(:result, kind: "ceinture")
      expect(result.challenge_validated?).to eq(false)
      result = create(:result, kind: "exercice",status: "failed")
      expect(result.challenge_validated?).to eq(false)
      result = create(:result, kind: "ceinture", status: "completed")
      expect(result.challenge_validated?).to eq(false)
    end
  end

  describe "#self.update_with_new_belt(belt)" do
  it "creates a new result for each skill in the belt domain" do
      Result.destroy_all
      belt = create(:belt, domain: @domain, level: 1)
      Result.update_with_new_belt(belt)
      expect(Result.count).to eq(belt.domain.skills.count)
    end
  end
end
