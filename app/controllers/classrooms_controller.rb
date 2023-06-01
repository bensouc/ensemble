# frozen_string_literal: true

class ClassroomsController < ApplicationController
  before_action :set_classroom, only: [:update, :destroy, :results, :results_by_domain]

  def index
    @school = current_user.school
    # @shared_classrooms = SharedClassroom.where(user: current_user)
    @shared_classrooms = current_user.shared_classrooms
    shared_classrooms = @shared_classrooms.includes([:classroom]).map(&:classroom)
    @classrooms = (current_user.classrooms + shared_classrooms).sort_by(&:created_at)
    @students_list = []
    @school_teachers = User.for_school(@school).reject { |y| y == current_user }
    @classrooms.each do |classroom|
      @students_list << [classroom, classroom.students]
    end
  end

  def create
    @classroom = Classroom.new(set_classroom_params)
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
    @skills = Skill.for_school(current_user.school).where(grade: @classroom.grade)
    # raise
    @domains.map do |domain|
      # remove domains without skills eg:poesie
      @domains.delete(domain) if @skills.select { |skill| skill.domain == domain }.empty?
    end
    @domain = @domains.first
    @skills = @skills.select { |skill| skill.domain == @domain }.sort
    results_factory # create all  variables shared with the results_by_domain Action
  end

  def results_by_domain
    # binding.pry
    @domain = set_domain
    results_factory # create all  variables shared with the results Action
    @skills = if @special_domain
                Skill.for_school(current_user.school).where(grade: @classroom.grade,
                                                            domain: @domain).sort_by(&:sub_domain)
              else
                Skill.for_school(current_user.school).where(grade: @classroom.grade, domain: @domain).sort
              end
    render partial: "classrooms/classroom_domain_results"
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
  end

  def set_domain
    params.require(:domain)
  end

  def set_classroom_params
    params.require(:classroom).permit(:grade, :name)
  end

  # COntroller Method

  # refacto of result and result_by_domain actions
  def results_factory
    # @special_domain = (WorkPlanDomain::DOMAINS_SPECIALS.include?(@domain) && @classroom.grade != "CM2")
    @special_domain = (WorkPlanDomain::DOMAINS_SPECIALS.include?(@domain) && @classroom.grade != "CM2")
    @students_list = @classroom.students.sort_by { |student| student.first_name.downcase }
    # get all validated belts for all classroom student
    @all_completed_belts = Belt.includes([:student]).where(student: @students_list, domain: @domain, completed: true)
    @all_completed_work_plan_skills = {}
    @students_list.each do |student|
      completed_wps = student.all_completed_work_plan_skills(@domain, @classroom.grade)
      @all_completed_work_plan_skills[student.id.to_s] = completed_wps unless completed_wps.empty?
    end
  end
end
