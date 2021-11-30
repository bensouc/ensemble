class WorkPlansController < ApplicationController
  def index
    @my_work_plans = WorkPlan.where(user: current_user)
  end

  def show
    @work_plan = WorkPlan.find(params[:id])
  end
end
