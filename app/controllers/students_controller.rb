# frozen_string_literal: true

class StudentsController < ApplicationController
  def show
    skip_authorization
    @student = Student.find(params[:id])
    @belt = Belt::BELT_COLORS
    # @all_skills_and_last_wps = []
    # @belts_specials_count = []
    # @student_grade = @student.classroom.grade
    @domains = @student.all_domains_from_student.sort_by(&:position)
    # @student_skills = @student_grade.skills
    # @belts = Belt.where(student: @student)
    # @belts = @belts.select(&:completed)
    # puts "Le last_wps :!!!!"
    # all_last_wps = WorkPlanSkill.last_wps(@student, @student_skills)
    # # WorkPlanSkill.where(student: student).max_by(&:created_at) fdf
    # puts "LE MAP"
    # # binding.pry
    # @all_skills_and_last_wps = @student_skills.map do |skill|
    #   next if all_last_wps.select { |wps| wps.skill == skill }.max_by(&:created_at).nil?

    #   {
    #     skill:,
    #     last_wps: get_last_completed_or_created_wps(all_last_wps, skill)
    #   }
    # end
    # @all_skills_and_last_wps.compact!.sort_by { |t| t[:last_wps][:updated_at] }
    # # retrive all student belts
    # # cleaning the useless lastwps (eg: special domain, remove the amount)
    # return if @student.classroom.user.school.special_domains? && @student_grade.grade_level == "CM2"

    # WorkPlanDomain::DOMAINS_SPECIALS.each do |domain|
    #   special_domain_belts = @belts.select { |belt| belt.domain == domain }
    #   count = special_domain_belts.count
    #   unless special_domain_belts.empty? || count.zero?
    #     @all_skills_and_last_wps = wps_cleaned_belt(@all_skills_and_last_wps, domain, count, @student_grade)
    #   end
    # end
  end

  def new
    skip_authorization
    @classroom = Classroom.find(classroom_params_id)
    @student = Student.new(classroom_id: @classroom.id)
  end

  def create
    skip_authorization
    student = {
      first_name: params_student[:first_name],
      classroom_id: params_student[:classroom].to_i,
    }
    @student = Student.create!(student)
    redirect_to classrooms_path
  end

  def update
    skip_authorization
    @student = Student.find(params[:id])
    @student.first_name = params_student_edit_name[:first_name]
    @student.save
    redirect_to classrooms_path
  end

  def destroy
    skip_authorization
    @student = Student.find(params[:id])
    @student.destroy
    redirect_to classrooms_path
  end

  def new_validated_wps
    # create the view for add validated skills on student
    skip_authorization
    @student = Student.includes(:classroom).find(params_add_validated_wps[:student_id])
    student_grade = @student.grade
    @special_work_plan = WorkPlan.find_or_create_by(student: @student, grade: student_grade, special_wps: true)
    domain = Domain.find(params_add_validated_wps[:domain])
    level = if domain.special?
        1
      else
        params_add_validated_wps[:level].to_i
      end
    skills = domain.skills.select { |skill| skill.level == level }
    @no_validated_skills = skills.reject { |skill| Result.find_by(skill:, student: @student, kind: "ceinture", status: "completed") }
    @subdomain = @no_validated_skills.map { |skill| skill.sub_domain }.compact.uniq
    # binding.pry
    unless @no_validated_skills.nil? || @no_validated_skills.empty?
      # redirect_to student_path(@student), flash: { notice: "Il n'y pas de compétence à ajouter pour ce domaine/niveau" }
      @special_work_plan.user = current_user
      @special_work_plan.name = "special_work_plan"
      @special_work_plan.save!
    end
  end

  def add_completed_wps
    skip_authorization
    student = Student.find(params_new_validated_wps[:student_id])
    skill = []
    skill << Skill.find(params_new_validated_wps[:skill_id])

    special_work_plan = student.find_special_workplan
    # binding.pry
    work_plan_domain = special_work_plan.work_plan_domains.find_or_create_by(
      domain: skill.first.domain,
      work_plan: special_work_plan,
      level: skill.first.level
    )
    # work_plan_domai.save
    @wps = WorkPlanDomain.add_wps_completed(skill, work_plan_domain, special_work_plan)
    if @wps.nil? # nil only if special domain
      render partial: "classrooms/results_wps_completed"
    else
      render partial: "work_plan_skills/add-special_wps"
    end
  end

  private

  def params_new_validated_wps
    params.permit(:student_id, :skill_id)
  end

  def params_add_validated_wps
    params.permit(:student_id, :level, :domain)
  end

  def params_student
    params.require(:student)
  end

  def params_student_edit_name
    params.require(:student).permit(:first_name)
  end

  def classroom_params_id
    params.require(:classroom_id)
  end

  # controller method to clean OOPed
  def wps_cleaned_belt(all_skills_last_wpss, domain, count, grade)
    # "Géométrie", "Grandeurs et Mesures"
    belt_validation = Belt.score_to_validate(grade)
    to_remove = belt_validation.find { |d| d[:domain] == domain }[:validation][count - 1]
    (1..to_remove).to_a.each do
      # get index for wps completed
      index = all_skills_last_wpss.index do |h|
        # binding.pry
        h[:skill][:domain] == domain && !h[:last_wps].nil? && h[:last_wps].status == "completed"
        # h[:skill][:domain] == domain && h[:skill][:grade] == grade && !h[:last_wps].nil? && h[:last_wps].status == "completed"
      end
      # delete @ index if index exists
      all_skills_last_wpss.delete_at(index) unless index.nil?
      # all_skills_last_wpss.select { |h| h[:skill][:domain] == domain && !h[:last_wps].nil? }.count
    end
    all_skills_last_wpss
  end

  def get_last_completed_or_created_wps(all_last_wps, skill)
    last_wps = all_last_wps.select { |wps| wps.skill == skill && wps.completed }.max_by(&:created_at)
    # find if one is completed then select it
    last_wps = all_last_wps.select { |wps| wps.skill == skill }.max_by(&:created_at) if last_wps.nil?
    last_wps
  end
end
