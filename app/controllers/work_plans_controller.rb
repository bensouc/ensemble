class WorkPlansController < ApplicationController
  def clone
    wp = WorkPlan.find(wp_id)
    # //crer des copie des WorkPlanDomain et de workplan skill
    new_wp = WorkPlan.create(
      {
        #work_plan_domain_ids: wp.work_plan_domain_ids,
        name: "#{wp.name} - CLONE",
        grade: wp.grade,
        user_id: current_user.id,
        start_date: wp.start_date,
        end_date: wp.end_date,
        student_id: wp.student_id,
      }
    )
    domains = WorkPlanDomain.where(work_plan_id: wp)
    domains.each do |domain|
      # copy domain
      copy_domain(domain, wp, new_wp)
    end
    if new_wp.save!
      redirect_to work_plan_path(new_wp), notice: "Clonage réussi"
    else
      redirect_to work_plan_path(wp), notice: "Clonage raté"
    end
  end

  def index
    # @my_work_plans = WorkPlan.where(user: current_user)
    # if params[:sort] != "avg_ranking"
    #   @my_work_plans = WorkPlan.where(user: current_user).order(params[:sort])
    # elsif params[:sort] == "avg_ranking"
    #   @my_work_plans = WorkPlan.where(user: current_user).sort_by { |player| player.avg_ranking }
    # else

    # recupere classrooms
    # recupe wstyudent from class room
    # recup work plan

    @my_classrooms = Classroom.where(user: current_user)
    @my_work_plans = WorkPlan.where(user: current_user).order(created_at: :DESC) #.sort_by(&:student)
    @my_work_plans_unassigned = @my_work_plans.where(student: nil)
    @my_work_plans = @my_work_plans.where.not(student: nil).sort_by(&:student)
  end

  def eval
    @belt = Belt::BELT_COLORS
    @work_plan = WorkPlan.find(params[:id])
    @previous = []
    # creating data to display previous evals#
    # retrieving all #workplandomains of @workplan
    @wpds = WorkPlanDomain.where(work_plan: @work_plan)
    @wpds.each do |wpd|
      wpd.work_plan_skills.each do |wps|
        # last_4_wps = WorkPlanSkill.where(student: @work_plan.student, skill: wps.skill_id).sort_by(&:created_at).reverse[1..3]
        last_4_wps = WorkPlanSkill.last_4_wps(@work_plan, wps)
        @previous << [wps.skill_id, last_4_wps]
      end
    end
  end

  def show
    @belt = Belt::BELT_COLORS
    @work_plan = WorkPlan.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "#{@work_plan.name} #{
          unless @work_plan.student.nil?
            @work_plan.student.first_name
          end
          }",
          template: "pdf/show_print.html.erb", # Excluding ".pdf" extension.
          disposition: "attachment",
          encoding: "utf8", # a remettre pour lle DL auto des pdf
          margin: {
            top: 5,
            bottom: 3,
            left: 5,
            right: 5,
          }
        # dpi: 300
      end
    end
  end

  def new
    @work_plan = WorkPlan.new
    # search all students of current-user
    @students = Student.where(classroom: current_user.classrooms)
    # generate the first work_plan_domain for new work_plan
    @work_plan_domain = @work_plan.work_plan_domains.new
    @levels = WorkPlanDomain::LEVELS
    # generate the first work_plan_skill for first work_plan_domain

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

  def update
    temp_wp = WorkPlan.new(true_wp_params)
    @work_plan = WorkPlan.find(params[:id])
    @work_plan.name = temp_wp.name
    @work_plan.start_date = temp_wp.start_date
    @work_plan.end_date = temp_wp.end_date
    @work_plan.student = temp_wp.student
    # update all domains and workplanskill students
    @work_plan.work_plan_domains.each do |domain|
      domain.student = temp_wp.student
      domain.save
      domain.work_plan_skills.each do |wps|
        wps.student = temp_wp.student
        wps.save
      end
    end
    if @work_plan.save
      redirect_to work_plan_path(@work_plan)
    else
      render :show
    end
  end

  def destroy
    @work_plan = WorkPlan.find(params[:id])
    @work_plan.destroy
    redirect_to work_plans_path
  end

  private

  def work_plan_params
    params.require(:work_plan).permit(:name, :student_id, :grade, :start_date, :end_date)
    # work_plan_domains_attributes: %i[domain level],
    # work_plan_skills_attributes: :name)
  end

  def true_wp_params
    params.require(:work_plan).permit(:name, :student_id, :start_date, :end_date, :id)
  end

  def wp_id
    params.require(:work_plan_id)
  end

  def work_plan_domain_params
    params[:work_plan].require(:work_plan_domain).permit(:domain, :level)
  end

  ###################### Subfonctions ##################
  def copy_domain(domain, wp, new_wp)
    new_wp_domain = domain.dup
    new_wp_domain.student = wp.student
    new_wp_domain.work_plan = new_wp
    new_wp_domain.save
    work_plan_skills = WorkPlanSkill.where(work_plan_domain_id: domain)
    work_plan_skills.each do |wps|
      wps.clone(wp, new_wp_domain)
    end
    new_wp_domain.save
  end
end
