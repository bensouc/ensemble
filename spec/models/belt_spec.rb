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
    it "returns false if Belt is not completed" do
      belt2 = build(:belt, completed: false)
      expect(belt2.completed?).to eq(false)
    end
  end

  describe "#all_skills(user)" do
    let(:school1) { create(:school) }
    let(:school2) { create(:school) }
    let(:usersolo) { create(:user, school: school1) }
    let(:user) { create(:user, school: school2) }
    let(:skillsolo) { create(:skill, school: school1) }
    let(:skill2) { create(:skill, school: school2) }
    let(:skill3) { create(:skill, domain: skill2.domain, grade: skill2.grade, level: skill2.level, school: school2) }
    let(:skill4) { create(:skill, domain: skill2.domain, grade: skill2.grade, level: skill2.level, school: school2) }
    let(:skill5) { create(:skill, domain: skill2.domain, grade: skill2.grade, level: skill2.level, school: school2) }
    let(:belt) { create(:belt, domain: skill2.domain, grade: skill2.grade, level: skill2.level) }
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
    let(:belt2) { create(:belt, student: belt1.student, domain: belt1.domain, grade: belt1.grade, level: 2, completed: true) }
    let(:belt3) { create(:belt, student: belt1.student, domain: belt1.domain, grade: belt1.grade, level: 3, completed: true) }
    let(:belt4) { create(:belt, student: belt1.student, domain: belt1.domain, grade: belt1.grade, level: 4, completed: true) }
    let(:belt5) { create(:belt, student: belt1.student, domain: belt1.domain, grade: belt1.grade, level: 5, completed: true) }
    let(:belt6) { create(:belt, student: belt1.student, domain: belt1.domain, grade: belt1.grade, level: 6, completed: false) }
    let(:belt7) { create(:belt, student: belt1.student, domain: belt1.domain, grade: belt1.grade, level: 7, completed: false) }
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

  describe "self.special_new_belt(work_plan_skill, work_plan)" do
    let(:student) { create(:student) }
    let(:grade) {create(:grade)}
    let(:work_plan) { create(:work_plan, grade: , student: ) }
    let(:work_plan_domain) { create(:work_plan_domain, work_plan: work_plan, domain: WorkPlanDomain::DOMAINS_SPECIALS.sample, level:1) }
    let(:skill) { create(:skill, domain: work_plan_domain.domain, grade: work_plan_domain.work_plan.grade, level: work_plan_domain.level)}
    let(:work_plan_skill) { create(:work_plan_skill, work_plan_domain: work_plan_domain, kind: 'ceinture', completed: true, status: "completed") }
    it "does not create a first new belt on special domains if its the first" do
      expect {
        Belt.special_newbelt(work_plan_skill, work_plan)
      }.to change(Belt, :count).by(0)
    end
  end
end
