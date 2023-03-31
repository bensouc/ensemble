# frozen_string_literal: true

class Classroom < ApplicationRecord
  GRADE = %w[CP CE1 CE2 CM1 CM2].freeze
  belongs_to :user

  has_many :students, dependent: :destroy
  has_many :shared_classrooms, dependent: nil

  validates :grade, presence: true

  # def students_list
  #   # Student.includes([:work_plans, :work_plan_skills]).where(classroom: self)
  #   Student.where(classroom: self)
  # end
end
