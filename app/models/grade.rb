class Grade < ApplicationRecord
  belongs_to :school
  validates :grade_level, presence: true, inclusion: Classroom::GRADE

  def self.find_grade_by_school_and_grade_level(school, grade_level)
    Grade.find_by(grade_level:, school:)
  end
end
