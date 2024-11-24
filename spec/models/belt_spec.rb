# frozen_string_literal: true

require "rails_helper"
RSpec.describe Belt, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    SchoolRole.destroy_all
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
    it "returns false if Belt is not completed (exo + true)" do
      belt2 = build(:belt,  completed: false)
      expect(belt2.completed?).to eq(false)
    end
  end

  describe "#completed!" do
    # let(:domain) { create(:domain, special: false) }
    # let(:belt) { create(:belt, completed: false, validated_date: nil, domain: domain) }

    it "marks the belt as completed" do
      @belt1.complete!
      expect(@belt1.completed).to be true
    end

    it "sets the validated_date to the current date and time" do
      @belt1.complete!
      expect(@belt1.validated_date).to be_within(1.second).of(DateTime.now)
    end

    it "sets a completed Result for all the skills of the domain and level" do
      belt2 = create(:belt)
      belt2.complete!
      belt2.domain.skills.select{|skill| skill.level == belt2.level}.each do |skill|
        result = Result.find_by(skill: skill, student: belt2.student)
        expect(result).to be_present
        expect(result.kind).to eq("ceinture")
        expect(result.status).to eq("completed")
      end
    end

    it "persists the changes to the database" do
      @belt1.complete!
      expect(@belt1.completed).to be true
      expect(@belt1.validated_date).to be_within(1.second).of(DateTime.now)
    end
  end

  describe "#all_skills(user)" do
    let(:school1) { create(:school) }
    let(:school2) { create(:school) }
    let(:usersolo) { create(:user, school: school1) }
    let(:user) { create(:user, school: school2) }
    let(:skillsolo) { create(:skill, school: school1) }
    let(:skill2) { create(:skill, school: school2) }
    let(:skill3) { create(:skill, domain: skill2.domain, level: skill2.level, school: school2) }
    let(:skill4) { create(:skill, domain: skill2.domain, level: skill2.level, school: school2) }
    let(:skill5) { create(:skill, domain: skill2.domain, level: skill2.level, school: school2) }
    let(:belt) { create(:belt, domain: skill2.domain, level: skill2.level) }
    it "returns all the skills for a given user based on its group/school" do
      expect(belt.all_skills(user)).to include(skill2)
      expect(belt.all_skills(user)).to include(skill3)
      expect(belt.all_skills(user)).to include(skill4)
      expect(belt.all_skills(user)).to include(skill5)
      expect(belt.all_skills(user)).to_not include(skillsolo)
    end
  end

  describe "#student_last_belt_level(student, domain)" do
    let(:belt1) { create(:belt, level: 1, completed: true) }
    let(:belt2) { create(:belt, student: belt1.student, domain: belt1.domain, level: 2, completed: true) }
    let(:belt3) { create(:belt, student: belt1.student, domain: belt1.domain, level: 3, completed: true) }
    let(:belt4) { create(:belt, student: belt1.student, domain: belt1.domain, level: 4, completed: true) }
    let(:belt5) { create(:belt, student: belt1.student, domain: belt1.domain, level: 5, completed: true) }
    let(:belt6) { create(:belt, student: belt1.student, domain: belt1.domain, level: 6, completed: false) }
    let(:belt7) { create(:belt, student: belt1.student, domain: belt1.domain, level: 7, completed: false) }
    it "returns the last belt level uncompleted by a student on domains not special" do
      belt1
      belt2
      belt3
      belt4
      belt5
      belt6
      belt7
      expect(Belt.student_last_belt_level(belt1.student, belt1.domain)).to eq(6)
    end
    it "returns 1 if no belt is completed" do
      belt1.completed = false
      belt1.save
      belt2.completed = false
      belt2.save
      belt3.completed = false
      belt3.save
      belt4.completed = false
      belt4.save
      belt5.completed = false
      belt5.save
      belt6.completed = false
      belt6.save
      belt7.completed = false
      belt7.save
      expect(Belt.student_last_belt_level(belt1.student, belt1.domain)).to eq(1)
    end
  end
end
