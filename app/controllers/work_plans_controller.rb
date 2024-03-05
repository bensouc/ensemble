# frozen_string_literal: true

class WorkPlansController < ApplicationController
  before_action :set_params_student, only: ["auto_new_wp"]
  before_action :setup_show, only: :show

  # And sharing
  def clone
    wp = WorkPlan.find(wp_id)
    skip_authorization
    # binding.pry
    # //crer des copie des WorkPlanDomain et de workplan skill
    # binding.pry
    students = multiplecloning_params(wp_id)

    # test if multiconing or simple clone/sharing
    if students.nil? || !sharing_params.nil?
      new_wp = WorkPlan.create(
        {
          # work_plan_domain_ids: wp.work_plan_domain_ids,
          name: wp.name.to_s,
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
        if sharing_params.nil?
          redirect_to work_plan_path(new_wp), notice: "Clonage réussi"
        else
          redirect_to work_plan_path(wp), notice: "Partage réussi"
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
            name: wp.name.to_s,
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
    skip_policy_scope
    shared_classrooms = current_user.user_shared_classrooms
    @my_classrooms = (current_user.classrooms + shared_classrooms).sort_by(&:created_at)
    @my_work_plans = current_user.all_classroom_workplans
    @my_work_plans_from_shared_classrooms = current_user.all_shared_classroom_workplans
    @my_work_plans += @my_work_plans_from_shared_classrooms unless @my_work_plans_from_shared_classrooms.empty?
    @my_work_plans = @my_work_plans.sort_by(&:created_at).reverse
    @my_work_plans_unassigned = WorkPlan.where(user: current_user, special_wps: false, student: nil)
  end

  def evaluation
    # binding.pry
    @work_plan = WorkPlan.find(params[:id])
    authorize @work_plan
    @domains = @work_plan.grade.domains.sort_by(&:position)
    @previous = []
    @student =@work_plan.student
    @wpds = @work_plan.work_plan_domains
    @wpds.each do |wpd|
      wpd.work_plan_skills.each do |wps|
        # last_4_wps = WorkPlanSkill.where(student: @work_plan.student, skill: wps.skill_id).sort_by(&:created_at).reverse[1..3]
        last_4_wps = WorkPlanSkill.last_4_wps(@work_plan, wps, @student)
        @previous << [wps.skill_id, last_4_wps]
      end
    end
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    unless @work_plan.shared_user_id.nil?
      @shared_user = current_user.collegues.find { |user| user.id == @work_plan.shared_user_id }
    end
    @teachers = current_user.collegues
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "#{@work_plan.name} #{@work_plan.student.first_name unless @work_plan.student.nil?}",
               template: "pdf/show_print",
               dpi: 380,
               formats: [:html],
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
    @grades = current_user.school.grades
    authorize @work_plan
    # search all students of current-user
    @students = Student.where(classroom: current_user.classrooms)
    # generate the first work_plan_domain for new work_plan
    @work_plan_domain = @work_plan.work_plan_domains.new
    # @levels = WorkPlanDomain::LEVELS
    # generate the first work_plan_skill for first work_plan_domain
  end

  def create
    @work_plan = WorkPlan.new(work_plan_params)
    authorize @work_plan
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
    authorize @work_plan
    @work_plan.name = temp_wp.name
    @work_plan.start_date = temp_wp.start_date
    @work_plan.end_date = temp_wp.end_date
    @work_plan.student = temp_wp.student
    if @work_plan.save!
      redirect_to work_plan_path(@work_plan)
    else
      render :show
    end
  end

  def destroy
    @work_plan = WorkPlan.find(params[:id])
    @student = @work_plan.student
    authorize @work_plan
    # p @student.work_plans.reject(&:special_wps).count
    if @student.nil?
      @work_plan.destroy
      @my_work_plans_unassigned = WorkPlan.where(user: current_user, special_wps: false, student: nil)
      @count = @my_work_plans_unassigned.count
    else
      @work_plan.destroy
      # @count = WorkPlan.where(student: @student).where.not(special_wps: true).count
      @count = WorkPlan.where.not(special_wps: true).where(student: @student).count
    end
    respond_to do |format|
      # format.html { redirect_to work_plans_path, notice: "Work plan was successfully destroyed." }
      format.turbo_stream
    end
  end

  def auto_new_wp
    if @domains.empty?
      redirect_to student_path(@student), notice: "Vous n'avez pas sélectionné de domaine"

      return
    end
    @work_plan = WorkPlan.new(
      name: "AUTO - N°#{@student.work_plans.count + 1}",
      grade: @student.classroom.grade,
      student: @student, user: current_user,
      start_date:Time.zone.today.next_occurring(:monday),
      end_date: Time.zone.today.next_occurring(:monday) + 4,
    )
    authorize @work_plan
    @work_plan.save
    # Iterate through each domain in the list of domains
    @domains.each do |domain|
      # Create a new WorkPlanDomain object and set its attributes
      wpd = WorkPlanDomain.create(domain:,
                                  level: Belt.student_last_belt_level(@student, domain),
                                  work_plan: @work_plan)

      # Check if the WorkPlanDomain has any specials and if the work plan grade is not "CM2"
      # if wpd.special? && @work_plan.grade != "CM2"
      if domain.special?

        # Set the WorkPlanDomain's level to 1 and save it
        wpd.level = 1
        wpd.save
      else
        # Find all the skills for the current domain, level, and grade
        Skill.for_school(current_user.school).where(domain:, level: wpd.level).each do |skill|

          # Find the most recent WorkPlanSkill object for the current student and skill
          # last_wps = WorkPlanSkill.last_wps(@student, skill).select { |wps| wps.skill == skill }.max_by(&:created_at)
          temp_last_wps = WorkPlanSkill.last_wps(@student, skill)
          last_wps = temp_last_wps.select { |wps| wps.skill == skill && wps.completed }.max_by(&:created_at)
          # find if one is completed then select it
          last_wps = temp_last_wps.select { |wps| wps.skill == skill }.max_by(&:created_at) if last_wps.nil?
          # else take the moste recent

          # Create a new WorkPlanSkill object and set its attributes
          new_wps = WorkPlanSkill.new(
            skill:,
            work_plan_domain: wpd,
            kind: "exercice",
          )
          # If there is no previous WorkPlanSkill, create a new challenge and save the new WorkPlanSkill
          if last_wps.nil?
            new_wps.challenge = new_wps.add_challenges_2_wps(current_user)
            new_wps.save

            # If the previous WorkPlanSkill is completed, create a new WorkPlanSkill of the appropriate kind and save it
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

            # If the previous WorkPlanSkill is not completed, create a new WorkPlanSkill of the appropriate kind and save it
          elsif %w[redo failed redo_OK new].include?(last_wps.status)
            new_wps[:kind] = last_wps.kind
            new_wps[:kind] = "exercice" if last_wps.kind == "ceinture"
            if new_wps.kind == "exercice"
              new_wps.challenge = last_wps.add_challenges_2_wps(current_user,
                                                                last_wps.challenge)
            end
            new_wps.save
          end
        end
      end
    end

    # Save the work plan and redirect to the appropriate page
    if @work_plan.save
      redirect_to work_plan_path(@work_plan)
    else
      redirect_to student_path(@student), notice: "Génération raté"
    end
  end

  private

  def sharing_params
    return if params[:work_plan].nil?

    params.require(:work_plan).permit(:shared_user_id)
  end

  def work_plan_params
    params.require(:work_plan).permit(:name, :student_id, :grade_id, :start_date, :end_date)
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
    @student = Student.find(params.require(:student_id))
    # binding.pry
    if params[:student].nil?
      @domains = params.require(:"/students/#{@student.id}")[:domains][1..].map {|id| Domain.find(id)}
    else
      @domains = params.require(:student)[:domains][1..].map {|id| Domain.find(id)}
    end
  end

  def multiplecloning_params(id)
    if params["/work_plans/#{id}"].nil?
      nil
    else
      params["/work_plans/#{id}"].require(:students)
    end
  end

  def setup_show
    @belt = Belt::BELT_COLORS
    @work_plan = WorkPlan.find(params[:id])
    @work_plan_domains = WorkPlanDomain.includes(:domain, :work_plan).where(work_plan:@work_plan)
    @domains = Domain.where(grade: @work_plan.grade).sort_by(&:position)
    @work_plan_skills = WorkPlanSkill.includes(:work_plan_domain,:skill, :challenge).where(work_plan_domain: @work_plan_domains)
    shared_classrooms = current_user.user_shared_classrooms
    @students = current_user.all_students
    @classrooms_whithout_current_student = current_user.classrooms + shared_classrooms
    authorize @work_plan
  end
  # def test_multiplecloning_params(id)
  #   params["/work_plans/#{id}"]
  # end

  ###################### Subfonctions ##################
  def copy_domain(domain, work_plan, new_wp)
    new_wp_domain = domain.dup
    # new_wp_domain.student = new_wp.student
    new_wp_domain.work_plan = new_wp
    new_wp_domain.save
    work_plan_skills = WorkPlanSkill.where(work_plan_domain_id: domain)
    work_plan_skills.each do |wps|
      wps.clone(work_plan, new_wp_domain)
    end
    new_wp_domain.save
  end
end
