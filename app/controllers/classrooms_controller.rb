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
    @domains.map do |domain|
      # remove domains without skills eg:poesie
      @domains.delete(domain) if @skills.none? { |skill| skill.domain == domain }
    end
    # raise
    respond_to do |format|
      format.html {
        @domain = @domains.first
        @skills = @skills.select { |skill| skill.domain == @domain }.sort
        set_up_results(@domain)
        results_factory(@domain) # create all  variables shared with the results_by_domain Action
      }
      format.xlsx {
        response.headers["Content-Disposition"] = 'attachment; filename="my_new_filename.xlsx"'
        generate_xlsx_file
      }
    end
  end

  def results_by_domain
    # binding.pry
    @domain = set_domain
    set_up_results(@domain)
    results_factory(@domain) # create all  variables shared with the results Action
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

  def generate_xlsx_file
    package = Axlsx::Package.new
    workbook = package.workbook
    header = ["Ceinture", "Compétences"]
    students_list = @classroom.students.sort_by { |student| student.first_name.downcase }
    header << students_list.map { |student| student.first_name.capitalize }
    # create a tab for each domain
    @domains.each do |domain|
      set_up_results(domain)
      results_factory(domain)
      # all_completed_belts = Belt.includes([:student]).where(student: students_list, domain: domain, completed: true)
      workbook.add_worksheet(name: "#{domain.capitalize}") do |sheet|
        sheet.add_row header.flatten
        @skills.select { |skill| skill.domain == domain }.sort_by { |skill| [skill.level, skill.id] }.each do |skill|
          sheet.add_row create_result_row(skill, students_list).flatten
        end
      end
    end
    # Enregistrez le fichier XLSX dans un temp file et envoyez-le en tant que pièce jointe
    temp_file = Tempfile.new("temp.xlsx")
    package.serialize(temp_file.path)
    send_file temp_file,
              filename: "#{@classroom.name}_resultats_#{Time.zone.today}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def create_result_row(skill, students_list)
    out = [Belt::BELT_COLORS[skill.level - 1], skill.name]
    out << students_list.map do |student|
      level = skill.specials? ?  1 : skill.level
      if @all_completed_belts.any? { |belt| belt.student == student && belt.domain == skill.domain && belt.level == level } ||
        @all_completed_work_plan_skills[student.id.to_s].to_a.any? { |wps| wps.skill == skill && wps.kind == "ceinture" && wps.completed }
        "X"
      end
    end
    out.flatten
  end

  # refacto of result and result_by_domain actions
  def set_up_results(domain)
    @special_domain = (WorkPlanDomain::DOMAINS_SPECIALS.include?(domain) && @classroom.grade != "CM2")
    @students_list = @classroom.students.sort_by { |student| student.first_name.downcase }
    # get all validated belts for all classroom student
    @all_completed_belts = Belt.includes([:student]).where(student: @students_list, domain: domain, completed: true)
  end

  def results_factory(domain)
    # @special_domain = (WorkPlanDomain::DOMAINS_SPECIALS.include?(@domain) && @classroom.grade != "CM2")
    @all_completed_work_plan_skills = {}
    @students_list.each do |student|
      completed_wps = student.all_completed_work_plan_skills(domain, @classroom.grade)
      @all_completed_work_plan_skills[student.id.to_s] = completed_wps unless completed_wps.empty?
    end
  end
end
