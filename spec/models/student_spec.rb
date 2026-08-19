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
    let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
    let(:other_grade) { create(:grade, school:, name: "CE2", grade_level: "CE2") }
    let(:origin) { create(:classroom, grade:) }
    let(:destination) { create(:classroom, grade:) }
    let(:other_level) { create(:classroom, grade: other_grade) }
    let(:student) { create(:student, classroom: origin) }

    it "propose les autres classes du même grade" do
      expect(student.transferable_classrooms).to include(destination)
    end

    it "exclut la classe actuelle de l'élève" do
      expect(student.transferable_classrooms).not_to include(origin)
    end

    it "exclut les classes d'un autre niveau" do
      expect(student.transferable_classrooms).not_to include(other_level)
    end
  end
end
