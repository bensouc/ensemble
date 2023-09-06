class SchoolsController < ApplicationController
  before_action :set_school, only: %w[show]

  def show
  end


  private

  def set_school
    @school = School.includes([:users, :classrooms]).find(params[:id])
    @classrooms = @school.classrooms
    @students = @school.all_students_list
  end
end
