# frozen_string_literal: true

require "rails_helper"
RSpec.describe Student, type: :model do
  before(:all) do
    Challenge.destroy_all
    SchoolRole.destroy_all
    User.destroy_all
    @student1 = create(:student)
  end

  it "is valid with valid attributes" do
    expect(@student1).to be_valid
    # p @skill1
  end

  describe "#transferable_classrooms" do
    let(:school) { create(:school) }
    let(:grade) { create(:grade, school:, name: "NivOrigine", grade_level: "CE1") }
    let(:other_grade) { create(:grade, school:, name: "NivAutre", grade_level: "CE2") }
    let(:origin) { create(:classroom, grade:) }
    let!(:destination) { create(:classroom, grade:) }
    let!(:other_level) { create(:classroom, grade: other_grade) }
    let(:student) { create(:student, classroom: origin) }

    it "ne propose que les autres classes du même niveau" do
      expect(student.transferable_classrooms).to contain_exactly(destination)
    end
  end
end
