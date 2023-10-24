class Grade < ApplicationRecord
  belongs_to :school
  validates :grade_level, presence: true, inclusion: Classroom::GRADE
end
