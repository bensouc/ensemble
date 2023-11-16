class GradesController < ApplicationController
  before_action :set_grade, only: [:show]

  def index
    @grades = policy_scope(Grade)
  end

  def new
    @grade = Grade.new(school: current_user.school)
    authorize @grade
  end

  def create
    @grade = Grade.new(grade_params)
    authorize @grade
    if @grade.save
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @grade = Grade.find(params[:id])
    authorize @grade
    @grade.destroy!
  end

  private

  def grade_params
    # "grade"=>{"grade_level"=>"CE1", "name"=>"test", "school
    params.require(:grade).permit(:grade_level, :name, :school_id)
  end

  def set_grade
    @grade = Grade.find(params[:id])
  end
end
