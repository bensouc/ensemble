# frozen_string_literal: true

class StudentsController < ApplicationController
  def new
    @classroom = Classroom.find(classroom_params_id)
    @student = Student.new(classroom_id: @classroom.id)
  end

  def show
    @student = Student.find(params[:id])
    @belt = Belt::BELT_COLORS
    @all_skills = []
    @belts_specials_count = []
    @student_grade = @student.classroom.grade
    @domains = @student.all_domains_from_student
    @student_skills = Skill.where(grade: @student_grade)
    @belts = Belt.where(student: @student, completed: true)
    all_last_wps = WorkPlanSkill.last_wps(@student, @student_skills)
    # WorkPlanSkill.where(student: student).max_by(&:created_at)
    @student_skills.each do |skill|
      @all_skills << {
        skill: skill,
        last_wps: all_last_wps.select { |wps| wps.skill == skill }.max_by(&:created_at),
      }
    end
    # retrive all student belts
    # cleaning the useless lastwps (eg: special domain, remove the amount)
    unless @student_grade == "CM2"
      WorkPlanDomain::DOMAINS_SPECIALS.each do |domain|
        special_belt = @belts.select { |belt| belt.domain == domain }
        count = special_belt.count
        unless special_belt.empty? || count.zero?
          @all_skills = wps_cleaned_belt(@all_skills, domain, count, @student_grade)
        end
      end
    end
  end

  def create
    student = {
      first_name: params_student[:first_name],
      classroom_id: params_student[:classroom].to_i,
    }
    @student = Student.create!(student)
    redirect_to classrooms_path
  end

  def destroy
    @student = Student.find(params[:id])
    @student.destroy
    redirect_to classrooms_path
  end

  def update
    @student = Student.find(params[:id])
    @student.first_name = params_student_edit_name[:first_name]
    @student.save
    redirect_to classrooms_path
  end

  def new_validated_wps
    @student = Student.includes(:classroom).find(params_add_validated_wps[:student_id])
    student_grade = @student.classroom.grade
    @special_work_plan = WorkPlan.find_or_create_by(student: @student, grade: student_grade, special_wps: true)
    domain = params_add_validated_wps[:domain]
    level = if WorkPlanDomain::DOMAINS_SPECIALS.include?(domain) && student_grade != "CM2"
              1
            else
              params_add_validated_wps[:level]
            end
    validated_work_plan_skills = WorkPlanSkill.includes([:skill, :work_plan_domain, :student]).where(status: "completed").select { |wps| wps.student == @student && wps.skill.domain == domain && wps.skill.level == level.to_i }
    validated_skill_id = validated_work_plan_skills.map { |wps| wps.skill.id}
    @skills = Skill.where(  level:,
                            domain:,
                            grade: student_grade
                          )
    @skills = @skills.reject{ |skill| validated_skill_id.include?(skill.id) }
    if @skills.empty?
      redirect_to student_path(@student), flash: {notice: "Il n'y pas de compétence à ajouter pour ce domaine/niveau"}
    else
    @special_work_plan.user = current_user
    @special_work_plan.name = "special_work_plan"
    @special_work_plan.save!
    end
  end

  private

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

  def wps_cleaned_belt(all_skills, domain, count, grade)
    # "Géométrie", "Grandeurs et Mesures"
    belt_validation = Belt.score_to_validate(grade)
    to_remove = belt_validation.select { |d| d[:domain] == domain }.first[:validation][count - 1]
    (1..to_remove).to_a.each do
      # get index for wps completed
      index = all_skills.index do |h|
        h[:skill][:domain] == domain && !h[:last_wps].nil? && h[:last_wps].status == "completed"
      end
      # delete @ index if index exists
      all_skills.delete_at(index) unless index.nil?
      # all_skills.select { |h| h[:skill][:domain] == domain && !h[:last_wps].nil? }.count
    end
    all_skills
  end
end
