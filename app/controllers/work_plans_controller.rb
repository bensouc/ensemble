# frozen_string_literal: true

class WorkPlansController < ApplicationController
  before_action :auto_new_wp_params, only: ["auto_new_wp"]
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
          message = current_user.first_name + " vous a partagé le  plan de travail " + new_wp.name.to_s
          SharingMessages.send_ensemble_message_to_user(new_wp.user, message)
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

    shared_classrooms = current_user.user_shared_classrooms.includes(:grade)
    @my_classrooms = (current_user.classrooms.includes(:grade) + shared_classrooms).sort_by(&:created_at)
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
    @student = @work_plan.student
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
        data_pdf = PdfGenerator::WorkPlanPdf.new(@work_plan, @belt, @work_plan_domains, @domains)
        send_data data_pdf.generate,
                  filename: "#{data_pdf.title}.pdf",
                  type: "application/pdf",
                  disposition: "attachment" # sending the pdf to the browser as a file
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
      format.html { redirect_to work_plans_path, notice: "Plan de travail supprimé" }
      format.turbo_stream { flash.now[:notice] = "Plan de travail supprimé" }
    end
  end

  def auto_new_wp
    if @domains.empty?
      redirect_to student_path(@student), notice: "Vous n'avez pas sélectionné de domaine"

      return
    end

    authorize @work_plan
    # Iterate through each domain in the list of domains
    @domains.each do |domain|
      # Create a new WorkPlanDomain object and set its attributes
      wpd = WorkPlanDomain.create(domain:,
                                  level: Belt.student_last_belt_level(@student, domain),
                                  work_plan: @work_plan)
      # Set the WorkPlanDomain's level to 1 and save it if Domain is special
      wpd.update(level: 1) if domain.special?
      # Find all the skills for the current domain, level, and grade
      wpd.attach_next_skills(current_user, @results)
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

  def auto_new_wp_params
    @student = Student.find(params.require(:student_id))
    @work_plan = WorkPlan.create(
      name: "AUTO - N°#{@student.work_plans.count + 1}",
      grade: @student.classroom.grade,
      student: @student, user: current_user,
      start_date: Time.zone.today.next_occurring(:monday),
      end_date: Time.zone.today.next_occurring(:monday) + 4,
    )
    @results = Result.includes(:skill).where(student: @student)
    # binding.pry
    @domains = if params[:student].nil?
                 params.require(:"/students/#{@student.id}")[:domains][1..].map { |id| Domain.find(id) }
               else
                 params.require(:student)[:domains][1..].map { |id| Domain.find(id) }
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
    @work_plan_domains = WorkPlanDomain.includes(:domain, :work_plan).where(work_plan: @work_plan)
    @domains = Domain.where(grade: @work_plan.grade).sort_by(&:position)
    @work_plan_skills = WorkPlanSkill.includes(:work_plan_domain, :skill, :challenge).where(work_plan_domain: @work_plan_domains)
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
