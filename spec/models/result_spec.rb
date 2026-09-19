require "rails_helper"

RSpec.describe Result, type: :model do
  before do
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

  # Une ceinture décrochée à l'évaluation se corrige depuis le plan de travail ;
  # ce qui a été posé à la main se retire à la main.
  describe "#deletable?" do
    it "refuse une ceinture validée née d'une évaluation" do
      result = create(:result, status: "completed", kind: "ceinture", origin: Result::EVALUATION)

      expect(result.deletable?).to be false
    end

    it "accepte une ceinture validée posée à la main" do
      result = create(:result, status: "completed", kind: "ceinture", origin: Result::DIRECT)

      expect(result.deletable?).to be true
    end

    it "accepte tout ce qui n'est pas une ceinture validée" do
      en_cours = create(:result, status: "failed", kind: "ceinture", origin: Result::EVALUATION)
      exercice = create(:result, status: "completed", kind: "exercice", origin: Result::EVALUATION)

      expect(en_cours.deletable?).to be true
      expect(exercice.deletable?).to be true
    end
  end

  describe "#validate!" do
    it "marque le résultat comme posé à la main" do
      result = create(:result, kind: "exercice", status: "new", origin: Result::EVALUATION)

      result.validate!

      expect(result.reload.origin).to eq(Result::DIRECT)
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
