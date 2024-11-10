# frozen_string_literal: true

class Classroom < ApplicationRecord
  GRADE = %w[CP CE1 CE2 CM1 CM2].freeze
  belongs_to :user
  belongs_to :grade #to remove for first migration Of Grade MODEL

  has_many :students, dependent: :destroy
  has_many :shared_classrooms, dependent: nil

  validates :grade, presence: true
  before_validation :set_default

  def shared?
    SharedClassroom.exists?(classroom: self)
  end

  def results_pdf_exists?
    zipfile_name = "classroom_#{id}_students_pdfs.zip"
    zipfile_path = Rails.root.join("public", "downloads", zipfile_name)
    if File.exist?(zipfile_path)
      creation_time = File.ctime(zipfile_path)
      return true, creation_time
    else
      return false, nil
    end
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
