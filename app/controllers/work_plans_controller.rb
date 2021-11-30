class WorkPlansController < ApplicationController
  def index
    @my_work_plans = WorkPlan.where(user: current_user)

  end
end
