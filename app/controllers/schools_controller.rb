class SchoolsController < ApplicationController
  before_action :set_school, only: %w[show]

  def show
    authorize @school
    @subscription = @school.subscription
    @grades = @school.grades
  end

  def new
    authorize School
    @sequence = 2
  end
  def create
    raise
    @school = School.new(school_params)
    @school.save
    levels = params[:levels][:grades][1..-1]
    levels.each do |grade|
      Grade.create(school: @school, grade_level: grade)
    end
    # creation subscription
    redirect_to
    # grades creation

  end

  def join
    authorize School
    @sequence = 2
  end

  private

  def set_school
    @school = School.includes([:users, :classrooms]).find(params[:id])
    @teachers = @school.users.order(:first_name).uniq.reject { |teacher| teacher.admin? }
    @classrooms = @school.classrooms
    @students = @school.all_students_list
  end

  def school_params
    params.required(:school).permit(:name,:email,:city)
  end
end
