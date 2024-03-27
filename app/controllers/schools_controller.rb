class SchoolsController < ApplicationController
  before_action :set_school, only: %w[show]

  def show
    authorize @school
    @subscription = @school.subscription
    @grades = @school.grades
  end

  def new
    @school = School.new
    authorize @school
    @sequence = 2
  end

  def create
    @school = School.new(school_params)
    authorize @school
    if @school.save
      prepare_grades_and_school_role
      @sequence = 3
      respond_to do |format|
        format.html { redirect_to new_subscription_path }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def join
    authorize School
    @sequence = 2
  end

  private

  def prepare_grades_and_school_role
    levels = params[:levels][:grades][1..-1]
    levels.each do |grade|
      Grade.create(school: @school, grade_level: grade)
    end
    @school.add_teacher(current_user, true)
    current_user.update(demo: false)
  end

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
