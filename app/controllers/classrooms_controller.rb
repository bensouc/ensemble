# frozen_string_literal: true

class ClassroomsController < ApplicationController
  before_action :set_classroom, only: [:update, :destroy, :results,:results_by_domain]

  def index
    @school = current_user.school
    # @shared_classrooms = SharedClassroom.where(user: current_user)
    @shared_classrooms = current_user.shared_classrooms
    shared_classrooms = @shared_classrooms.includes([:classroom]).map(&:classroom)
    @classrooms = (current_user.classrooms + shared_classrooms).sort_by(&:created_at)
    @students_list = []
    @school_teachers = User.where(school: @school).reject { |y| y == current_user }
    @classrooms.each do |classroom|
      @students_list << [classroom, classroom.students]
    end
  end

  def create
    @classroom = Classroom.create(set_classroom_params)
    @classroom.user = current_user
    @classroom.name = nil if @classroom.name == ""
    @classroom.save!
    redirect_to classrooms_path
  end

  def update
    @classroom.name = set_classroom_params[:name]
    @classroom.name = nil if @classroom.name == ""
    @classroom.save!
    redirect_to classrooms_path
  end

  def destroy
    @classroom.destroy
    redirect_to classrooms_path
  end

  def results
    @domains = WorkPlanDomain::DOMAINS[@classroom.grade]
    @special_domain = (WorkPlanDomain::DOMAINS_SPECIALS.include?(@domain) && @classroom.grade != 'CM2')
    @skills = Skill.where(grade: @classroom.grade)
    @domain = @domains.first
    @students_list = @classroom.students_list.sort_by{|student| student.first_name.downcase}

    # get all validated belts for all classroom student
    @all_completed_belts = Belt.includes([:student]).where(student: @students_list, domain: @domain, completed: true)
    # @all_completed_belts = Belt.includes([:students]).where(students: @students_list, domain: domain, completed: true)
    # raise
    @all_completed_work_plan_skills = @students_list.map do |student|
      completed_wps = student.all_completed_work_plan_skills(@domain, @classroom.grade)
      {
        student.id.to_s => completed_wps
      } unless completed_wps.empty?
    end
    @all_completed_work_plan_skills = @all_completed_work_plan_skills.first
  end

  def results_by_domain
    @domain = set_domain
    @special_domain = (WorkPlanDomain::DOMAINS_SPECIALS.include?(@domain) && @classroom.grade != 'CM2')
    @skills = Skill.where(grade: @classroom.grade, domain: @domain)
    @students_list = @classroom.students_list
    @all_completed_belts = Belt.includes([:student]).where(student: @students_list, domain: @domain, completed: true)
    @all_completed_work_plan_skills = @students_list.map do |student|
      completed_wps = student.all_completed_work_plan_skills(@domain, @classroom.grade)
      {
        student.id.to_s => completed_wps
      } unless completed_wps.empty?
    end
    @all_completed_work_plan_skills = @all_completed_work_plan_skills.first
    # raise
    render partial:'classrooms/classroom_domain_results'
  end

  private

  def set_classroom
    @classroom = Classroom.includes([:students]).find(params[:id])
  end

  def set_domain
    params.require(:domain)
  end

  def set_classroom_params
    params.require(:classroom).permit(:grade, :name)
  end
end
