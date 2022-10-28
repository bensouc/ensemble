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
    Skill.where(grade: @student_grade).each do |skill|
      @all_skills << {
        skill: skill,
        last_wps: WorkPlanSkill.last_wps(@student, skill.id)
      }
    end
    # retrive all student belts
    @belts = Belt.where(student: @student, grade: @student_grade)
    # cleaning the useless lastwps (eg: special domain, remove the amount)
    unless @student_grade == "CM2"
      WorkPlanDomain::DOMAINS_SPECIALS.each do |domain|
        count = @belts.where(domain: domain, completed: true).count
        unless @belts.where(domain: domain).empty? || count.zero?
          @all_skills = wps_cleaned_belt(@all_skills, domain, count, @student_grade)
        end
      end
    end
  end

  def create
    student = {
      first_name: params_student[:first_name],
      classroom_id: params_student[:classroom].to_i
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

  private

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
