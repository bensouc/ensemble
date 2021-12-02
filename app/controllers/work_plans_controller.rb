class WorkPlansController < ApplicationController
  def index
    @my_work_plans = WorkPlan.where(user: current_user)
  end

  def show
    @belt = %w(blanche jaune orange verte bleue marron noire)
    @work_plan = WorkPlan.find(params[:id])
  end

  def new
    @work_plan = WorkPlan.new

    # search all students of current-user
    @students = Student.where(classroom: current_user.classrooms)

    # generate the first work_plan_domain for new work_plan
    @work_plan_domain = @work_plan.work_plan_domains.new

    # generate the first work_plan_skill for first work_plan_domain
    @work_plan_domain.work_plan_skills.new
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
    params.require(:work_plan).permit(:name, :student_id, :start_date, :end_date,
                                      work_plan_domains_attributes: %i[domain level],
                                      work_plan_skills_attributes: :name)
  end
end
