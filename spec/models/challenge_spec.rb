# frozen_string_literal: true

require "rails_helper"
RSpec.describe Challenge, type: :model do
  before(:all) do
    Challenge.destroy_all
    SchoolRole.destroy_all
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

  describe "ordre au sein d'une compétence" do
    let(:skill) { create(:skill) }

    it "place un nouvel exercice en fin de liste" do
      first = create(:challenge, skill:)
      second = create(:challenge, skill:)

      expect([first.position, second.position]).to eq([1, 2])
    end

    it "numérote séparément les exercices classiques et ceux de ceinture" do
      classic = create(:challenge, skill:)
      belt = create(:challenge, skill:, for_belt: true)

      expect([classic.position, belt.position]).to eq([1, 1])
    end

    it "échange deux positions avec move_higher / move_lower" do
      first = create(:challenge, skill:)
      second = create(:challenge, skill:)

      second.move_higher

      expect([first.reload.position, second.reload.position]).to eq([2, 1])

      second.move_lower

      expect([first.reload.position, second.reload.position]).to eq([1, 2])
    end

    it "renumérote la liste quand un exercice est supprimé" do
      create(:challenge, skill:)
      middle = create(:challenge, skill:)
      last = create(:challenge, skill:)

      middle.destroy

      expect(last.reload.position).to eq(2)
    end

    it "ordonne la liste avec le scope ordered" do
      first = create(:challenge, skill:)
      second = create(:challenge, skill:)
      second.move_to_top

      expect(Challenge.where(skill:).ordered.to_a).to eq([second, first])
    end
  end
end
