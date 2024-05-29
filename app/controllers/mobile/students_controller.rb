class Mobile::StudentsController < ApplicationController
  layout "mobile"
  before_action :set_student, only: [:show]

  def index
    @students = policy_scope(Student)
  end

  def show
    authorize @student
    @belts = Belt.completed.where(student: @student)
    @domains = @student.all_domains_from_student.sort_by(&:position)
    # binding.pry

  end

  private

  def set_student
    @student = Student.find(params[:id])
    @classroom = @student.classroom
  end
end
