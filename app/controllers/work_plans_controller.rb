# frozen_string_literal: true

class WorkPlansController < ApplicationController
  def clone #And sharing
    wp = WorkPlan.find(wp_id)
    # //crer des copie des WorkPlanDomain et de workplan skill

    students = multiplecloning_params(wp_id)

    # test if multiconing or simple clone/sharing
    if students.nil? || !sharing_params.nil?
      new_wp = WorkPlan.create(
        {
          # work_plan_domain_ids: wp.work_plan_domain_ids,
          name: "#{wp.name}",
          grade: wp.grade,
          user_id: current_user.id,
          start_date: wp.start_date,
          end_date: wp.end_date,
        # student_id: wp.student_id
        }
      )
      unless sharing_params.nil?
        new_wp.user_id = sharing_params[:shared_user_id]
        new_wp.shared_user = current_user
      end
      domains = WorkPlanDomain.where(work_plan_id: wp)
      domains.each do |domain|
        # copy domain
        copy_domain(domain, wp, new_wp)
      end
      if new_wp.save!
        unless sharing_params.nil?
          redirect_to work_plan_path(wp), notice: "Partage réussi"
        else
          redirect_to work_plan_path(new_wp), notice: "Clonage réussi"
        end
      else
        redirect_to work_plan_path(wp), notice: "Clonage raté"
      end
    else
      students = students.reject(&:blank?)
      students = students.reject { |n| n.to_i.negative? }
      students.delete("0")
      students.each do |clone_student_id|
        new_wp = WorkPlan.create!(
          {
            # work_plan_domain_ids: wp.work_plan_domain_ids,
            name: "#{wp.name}",
            grade: wp.grade,
            user_id: current_user.id,
            start_date: wp.start_date,
            end_date: wp.end_date,
            student_id: Student.find(clone_student_id).id,
          }
        )

        domains = WorkPlanDomain.where(work_plan_id: wp)
        domains.each do |domain|
          # copy domain
          copy_domain(domain, wp, new_wp)
        end
        new_wp.save!
      end
      redirect_to work_plans_path
    end
  end

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

  def show
    @belt = Belt::BELT_COLORS
    @work_plan = WorkPlan.find(params[:id])
    @domains = @work_plan.all_domains_from_work_plan
    @classrooms_whithout_current_student = current_user.classrooms
    unless @work_plan.shared_user_id.nil?
      @shared_user = User.find(@work_plan.shared_user_id)
    end
    @teachers = User.all.reject { |y| y == current_user }
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "#{@work_plan.name} #{@work_plan.student.first_name unless @work_plan.student.nil?}",
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
    # @levels = WorkPlanDomain::LEVELS
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

  def auto_new_wp
    @student = Student.find(set_params_student)
    @work_plan = WorkPlan.create(
      name: "AUTO - N°#{@student.work_plans.count + 1}",
      grade: @student.classroom.grade,
      student: @student, user: current_user,
      start_date: Date.today.next_occurring(:monday),
      end_date: Date.today.next_occurring(:friday),
    )

    # ajout date intro prendre date => first monday => first friday
    # based on student classroom level,
    @student.all_domains_from_student.each do |domain|
      # loop on DOMAINS => create wpdomain

      # to choose which level => 1 find last student.belt.completed true => level +1 else belts level = 1
      # level = Belt.student_last_belt_level(@student, domain)
      wpd = WorkPlanDomain.create(domain: domain,
                                  level: Belt.student_last_belt_level(@student, domain),
                                  student: @student,
                                  work_plan: @work_plan)

      if WorkPlanDomain::DOMAINS_SPECIALS.include?(domain) && @work_plan.grade != "CM2"
        # mngt of special domains
        wpd.level = 1
        wpd.save
      else
        Skill.where(domain: domain, level: wpd.level, grade: @student.classroom.grade).each do |skill|
          # Loop on skills 4 domain grade level
          # get last wps
          last_wps = WorkPlanSkill.last_wps(@student.id, skill.id)
          # raise
          new_wps = WorkPlanSkill.new(
            skill: skill,
            student: @student,
            work_plan_domain: wpd,
            kind: "exercice",
          )
          if last_wps.nil?
            # create a new wps with same kind and
            new_wps.challenge = new_wps.add_challenges_2_wps(current_user)
            new_wps.save
            # if last wps is completed
          elsif last_wps.status == "completed"
            case last_wps.kind
            when "jeu"
              new_wps[:kind] = "exercice"
              new_wps.challenge = new_wps.add_challenges_2_wps(current_user)
              new_wps.save
            when "exercice"
              new_wps[:kind] = "ceinture"
              new_wps.save
            end
            # sinon redo failed redo_OK new => a wps with same kind with new status
          elsif %w[redo failed redo_OK new].include?(last_wps.status)
            new_wps[:kind] = last_wps.kind
            if last_wps.kind == "ceinture"
              new_wps[:kind] = "exercice"
            end
            # create a new wps with same kind and
            if new_wps.kind == "exercice"
              new_wps.challenge = last_wps.add_challenges_2_wps(current_user,
                                                                last_wps.challenge)
            end
            new_wps.save
          end
        end
      end
    end
    if @work_plan.save
      redirect_to work_plan_path(@work_plan)
    else
      redirect_to student_path(@student), notice: "Génération raté"
    end
  end

  private

  def sharing_params
    unless params[:work_plan].nil?
      params.require(:work_plan).permit(:shared_user_id)
    else
      nil
    end
  end

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

  def set_params_student
    params.require(:student_id)
  end

  def multiplecloning_params(id)
    if params["/work_plans/#{id}"].nil?
      nil
    else
      params["/work_plans/#{id}"].require(:students)
    end
  end

  # def test_multiplecloning_params(id)
  #   params["/work_plans/#{id}"]
  # end

  ###################### Subfonctions ##################
  def copy_domain(domain, work_plan, new_wp)
    new_wp_domain = domain.dup
    new_wp_domain.student = new_wp.student
    new_wp_domain.work_plan = new_wp
    new_wp_domain.save
    work_plan_skills = WorkPlanSkill.where(work_plan_domain_id: domain)
    work_plan_skills.each do |wps|
      wps.clone(work_plan, new_wp_domain, new_wp.student)
    end
    new_wp_domain.save
  end
end
