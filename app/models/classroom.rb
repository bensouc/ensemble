# frozen_string_literal: true

class Classroom < ApplicationRecord
  GRADE = %w[CP CE1 CE2 CM1 CM2].freeze
  belongs_to :user

  has_many :students, dependent: :destroy
  has_many :shared_classroom, dependent: nil

  validates :grade, presence: true

  # def student_list
  #   Student.where(classroom_id: id)
  # end
end
