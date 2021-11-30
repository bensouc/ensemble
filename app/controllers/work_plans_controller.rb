class WorkPlansController < ApplicationController
  def index
    @my_work_plans = WorkPlan.where(user: current_user)
  end

  def new
    @work_plan = WorkPlan.new
    @students = Student.where(classroom: current_user.classrooms)
  end

  def create
    @work_plan = WorkPlan.new(work_plan_params)
    @work_plan.user = current_user
    if @work_plan.save!
      redirect_to work_plan_path(@work_plan)
    else
      render 'new'
    end
  end

  private

  def work_plan_params
    params.require(:work_plan).permit(:name, :student_id)
  end
end
