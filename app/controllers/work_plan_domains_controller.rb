class WorkPlanDomainsController < ApplicationController

  def create

      @work_plan = WorkPlan.find(params_wp_id)
      @domain = WorkPlanDomain.new(work_plan_domain_params)
      @domain.work_plan = @work_plan
      if ['Géométrie', 'Grandeurs et Mesures'].include?(@domain.domain)
        @domain.level= 1
      end
      if @domain.save
        redirect_to work_plan_path(@work_plan, anchor: 'bottom')
      else
        redirect_to work_plan_path(@work_plan, anchor: 'dmn-validate')
      end
  end

  def destroy
    @work_plan_domain = WorkPlanDomain.find(params[:id])
    # raise
    @work_plan_domain.destroy
    redirect_to work_plan_path(@work_plan_domain.work_plan)
  end

  private

  def params_wp_id
    params.require(:work_plan_id)
  end

  def work_plan_domain_params
    params[:work_plan].require(:work_plan_domain).permit(:domain, :level)
  end
end
