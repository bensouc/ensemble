class Mobile::WorkPlansController < ApplicationController
  def index
    # @my_classrooms = Classroom.where(user: current_user)
    # @my_work_plans = WorkPlan.where(user: current_user).order(created_at: :DESC) # .sort_by(&:student)
    # @my_work_plans_unassigned = @my_work_plans.where(student: nil)
    # @my_work_plans = @my_work_plans.where.not(student: nil).sort_by(&:student)
    @shared_classrooms = current_user.shared_classrooms
    shared_classrooms = @shared_classrooms.map(&:classroom)
    @my_classrooms = (current_user.classrooms + shared_classrooms).sort_by(&:created_at)
    shared_work_plans = []
    shared_classrooms.each do |classroom|
      classroom.students.each do |shared_student|
        WorkPlan.where(student: shared_student, special_wps: false).order(created_at: :DESC).each do |work_plan|
          shared_work_plans << work_plan
        end
      end
    end
    @my_work_plans = policy_scope(WorkPlan)
    # .sort_by(&:student)
    @my_work_plans_unassigned = @my_work_plans.where(student: nil)
    @my_work_plans = @my_work_plans.where.not(student: nil).sort_by(&:student)
    @my_work_plans += shared_work_plans
  end

  def evaluation
    # @belt = Belt::BELT_COLORS
    @work_plan = WorkPlan.find(params[:id])
    authorize @work_plan
    @domains = @work_plan.all_domains_from_work_plan
    @previous = []
    @wpds = WorkPlanDomain.where(work_plan: @work_plan)
    @wpds.each do |wpd|
      wpd.work_plan_skills.each do |wps|
        # last_4_wps = WorkPlanSkill.where(student: @work_plan.student, skill: wps.skill_id).sort_by(&:created_at).reverse[1..3]
        last_4_wps = WorkPlanSkill.last_4_wps(@work_plan, wps, @work_plan.student)
        @previous << [wps.skill_id, last_4_wps]
      end
    end
  end
end
