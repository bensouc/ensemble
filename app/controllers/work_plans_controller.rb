class WorkPlansController < ApplicationController
  def index
    @my_work_plans = WorkPlan.where(user: current_user)
  end

  def show
    @work_plan = WorkPlan.find(params[:id])
  end

  def new
    @work_plan = WorkPlan.new
    # search all students of current-user
    @students = Student.where(classroom: current_user.classrooms)
  end

  def create
    @work_plan = WorkPlan.new(work_plan_params)
    @work_plan.user = current_user
    if @work_plan.save
      redirect_to work_plan_path(@work_plan)
    else
      redirect_to new_work_plan_path
    end
  end

  private

  def work_plan_params
    params.require(:work_plan).permit(:name, :student_id)
  end

end
