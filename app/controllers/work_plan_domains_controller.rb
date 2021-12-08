class WorkPlanDomainsController < ApplicationController
  def destroy
    @work_plan_domain = WorkPlanDomain.find(params[:id])
    # raise
    @work_plan_domain.destroy
    redirect_to work_plan_path(@work_plan_domain.work_plan)
  end
end
