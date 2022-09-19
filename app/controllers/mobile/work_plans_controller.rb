class Mobile::WorkPlansController < ApplicationController
  def index
    @my_classrooms = Classroom.where(user: current_user)
    @my_work_plans = WorkPlan.where(user: current_user).order(created_at: :DESC) # .sort_by(&:student)
    @my_work_plans_unassigned = @my_work_plans.where(student: nil)
    @my_work_plans = @my_work_plans.where.not(student: nil).sort_by(&:student)
  end

  def eval
    # @belt = Belt::BELT_COLORS
    @work_plan = WorkPlan.find(params[:id])
    @domains = @work_plan.all_domains_from_work_plan
    @previous = []
    @wpds = WorkPlanDomain.where(work_plan: @work_plan)
    @wpds.each do |wpd|
      wpd.work_plan_skills.each do |wps|
        # last_4_wps = WorkPlanSkill.where(student: @work_plan.student, skill: wps.skill_id).sort_by(&:created_at).reverse[1..3]
        last_4_wps = WorkPlanSkill.last_4_wps(@work_plan, wps)
        @previous << [wps.skill_id, last_4_wps]
      end
    end
  end
end
