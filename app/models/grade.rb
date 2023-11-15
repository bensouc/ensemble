class Grade < ApplicationRecord
  belongs_to :school
  has_many :classrooms
  has_many :skills, through: :school
  has_many :students, through: :classrooms, source: "students"

  validates :grade_level, presence: true, inclusion: Classroom::GRADE

  before_validation :set_default

  def self.find_grade_by_school_and_grade_level(school, grade_level)
    Grade.find_by(grade_level:, school:)
  end

  private

  def set_default
    self.name = grade_level if name.nil? || name == ""
  end
end
