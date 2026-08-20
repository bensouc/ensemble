# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPlanSkill, type: :model do
  let(:user) { create(:user) }
  let(:classroom) { create(:classroom, user:) }
  let(:student) { create(:student, classroom:) }
  let(:work_plan) { create(:work_plan, user:, student:) }
  let(:work_plan_domain) { create(:work_plan_domain, work_plan:) }
  let(:skill) { create(:skill, school: user.school) }

  def new_exercice_wps
    WorkPlanSkill.new(skill:, work_plan_domain:, kind: "exercice", status: "new")
  end

  def existing_exercice_wps(challenge:, status:)
    WorkPlanSkill.create!(skill:, work_plan_domain:, kind: "exercice", status:, challenge:)
  end

  describe "#get_challenge_4_wps" do
    it "prend le premier exercice de la compétence dans l'ordre des positions" do
      first_created = create(:challenge, user:, skill:)
      second_created = create(:challenge, user:, skill:)
      second_created.move_to_top

      expect(new_exercice_wps.get_challenge_4_wps).to eq(second_created)
      expect(second_created.position).to be < first_created.reload.position
    end

    it "saute les exercices que l'élève a déjà eus" do
      already_done = create(:challenge, user:, skill:)
      next_one = create(:challenge, user:, skill:)
      existing_exercice_wps(challenge: already_done, status: "completed")

      expect(new_exercice_wps.get_challenge_4_wps).to eq(next_one)
    end

    it "renvoie nil quand l'élève a eu tous les exercices de la compétence" do
      only_one = create(:challenge, user:, skill:)
      existing_exercice_wps(challenge: only_one, status: "completed")

      expect(new_exercice_wps.get_challenge_4_wps).to be_nil
    end

    it "ne crée plus d'exercice vide quand la liste est épuisée" do
      existing_exercice_wps(challenge: create(:challenge, user:, skill:), status: "completed")

      expect { new_exercice_wps.get_challenge_4_wps }.not_to change(Challenge, :count)
    end

    it "rejoue l'exercice du dernier plan de travail resté à faire" do
      not_done_yet = create(:challenge, user:, skill:)
      create(:challenge, user:, skill:)
      existing_exercice_wps(challenge: not_done_yet, status: "new")

      expect(new_exercice_wps.get_challenge_4_wps).to eq(not_done_yet)
    end

    it "ne plante pas quand le dernier plan de travail à faire n'a pas d'exercice" do
      available = create(:challenge, user:, skill:)
      existing_exercice_wps(challenge: nil, status: "new")

      expect(new_exercice_wps.get_challenge_4_wps).to eq(available)
    end

    it "ignore les exercices de ceinture" do
      create(:challenge, user:, skill:, for_belt: true)

      expect(new_exercice_wps.get_challenge_4_wps).to be_nil
    end

    it "ignore les exercices attribués à un autre élève" do
      other_student = create(:student, classroom:)
      other_wpd = create(:work_plan_domain, work_plan: create(:work_plan, user:, student: other_student))
      taken_by_other = create(:challenge, user:, skill:)
      WorkPlanSkill.create!(skill:, work_plan_domain: other_wpd, kind: "exercice",
                            status: "completed", challenge: taken_by_other)

      expect(new_exercice_wps.get_challenge_4_wps).to eq(taken_by_other)
    end
  end
end
