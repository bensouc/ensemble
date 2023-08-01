# frozen_string_literal: true

class Classroom < ApplicationRecord
  GRADE = %w[CP CE1 CE2 CM1 CM2].freeze
  belongs_to :user

  has_many :students, dependent: :destroy
  has_many :shared_classrooms, dependent: nil

  validates :grade, presence: true

  def shared?
    SharedClassroom.exists?(classroom: self)
  end


  def shared_user
    return unless shared?

    SharedClassroom.select { |s_classroom| s_classroom.classroom == self }.first.user
  end

  # def students_list
  #   # Student.includes([:work_plans, :work_plan_skills]).where(classroom: self)
  #   Student.where(classroom: self)
  # end
end
