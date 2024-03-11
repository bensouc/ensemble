class SchoolsController < ApplicationController
  before_action :set_school, only: %w[show]

  def join
    raise
  end

  def show
    authorize @school
    @subscription = @school.subscription
    @grades = @school.grades
  end


  private

  def set_school
    @school = School.includes([:users, :classrooms]).find(params[:id])
    @teachers = @school.users.order(:first_name).uniq.reject{|teacher| teacher.admin?}
    @classrooms = @school.classrooms
    @students = @school.all_students_list
  end
end
