# frozen_string_literal: true

class Classroom < ApplicationRecord
  GRADE = %w[CP CE1 CE2 CM1 CM2].freeze
  belongs_to :user
  belongs_to :grade #to remove for first migration

  has_many :students, dependent: :destroy
  has_many :shared_classrooms, dependent: nil

  validates :grade, presence: true
  before_validation :set_default

  def shared?
    SharedClassroom.exists?(classroom: self)
  end


  def shared_user
    return unless shared?

    SharedClassroom.select { |s_classroom| s_classroom.classroom == self }.first.user
  end


  private

  def set_default
    self.name = "" if name.nil? || name == ""
  end
end
