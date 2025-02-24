# frozen_string_literal: true

class Classroom < ApplicationRecord
  GRADE = %w[CP CE1 CE2 CM1 CM2].freeze
  belongs_to :user
  belongs_to :grade # to remove for first migration Of Grade MODEL

  has_many :students, dependent: :destroy
  has_many :shared_classrooms, dependent: nil

  before_validation :set_default

  def shared?
    SharedClassroom.exists?(classroom: self)
  end

  def results_pdf_exists?
    zipfile_name = "classroom_#{id}_students_pdfs.zip"
    zipfile_path = Rails.root.join("tmp", zipfile_name)
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

  def safe_name
    name == "" ? grade.grade_level : name
  end

  def completed_results_by_domain(domain)
      # {student_id: Result.where(skills: domain.skills, student: student)}
    results = {}
    temp_results = Result.includes([:student, :skill])
                      .where(skill: domain.skills)
                      .where(student_id: students.pluck(:id))
                      .where(status: "completed")
                      .where(kind: "ceinture")
    students.each do |student|
      results[student] = temp_results.select { |result| result.student_id == student.id }
    end
    results
  end
  private

  def set_default
    self.name = "" if name.nil? || name == ""
  end
end
