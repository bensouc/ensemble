require "rails_helper"

RSpec.describe School, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    Belt.destroy_all
    SchoolRole.destroy_all
    User.destroy_all
    School.destroy_all
    @school = create(:school)
  end
  it " is valid with valid attributes" do
    expect(@school).to be_valid
  end

  describe "#all_students_list" do
    it "returns a list of all students of this particular School" do
      user1 = create(:user, school: @school)
      user2 = create(:user, school: @school)
      school2 = create(:school)
      user3 = create(:user, school: school2)
      classroom1 = create(:classroom, user: user1)
      classroom2 = create(:classroom, user: user2)
      classroom3 = create(:classroom, user: user3)
      student1 = create(:student, classroom: classroom1)
      student2 = create(:student, classroom: classroom1)
      student3 = create(:student, classroom: classroom2)
      student4 = create(:student, classroom: classroom2)
      student5 = create(:student, classroom: classroom2)
      student6 = create(:student, classroom: classroom3)
      student7 = create(:student, classroom: classroom3)
      expect(@school.all_students_list.count).to eq(5)
    end
  end
end
