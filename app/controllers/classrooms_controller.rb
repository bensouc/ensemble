# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength

class ClassroomsController < ApplicationController
  before_action :set_classroom, only: [:update, :destroy, :results, :results_by_domain]

  def index
    @school = policy_scope(School)
    # @shared_classrooms = SharedClassroom.where(user: current_user)
    @shared_classrooms = policy_scope(SharedClassroom)
    shared_classrooms = @shared_classrooms.includes([:classroom]).map(&:classroom)
    @classrooms = (policy_scope(Classroom) + shared_classrooms).sort_by(&:created_at)
    @school_grades = @school.grades
    @students_list = []
    @school_teachers = current_user.collegues
    @classrooms.each do |classroom|
      @students_list << [classroom, classroom.students]
    end
  end

  def create
    @classroom = Classroom.new(set_classroom_params)
    skip_authorization
    @classroom.user = current_user
    @classroom.name = nil if @classroom.name == ""
    @classroom.save!
    redirect_to classrooms_path
  end

  def update
    skip_authorization
    @classroom.name = set_classroom_params[:name]
    @classroom.name = nil if @classroom.name == ""
    @classroom.save!
    redirect_to classrooms_path
  end

  def destroy
    # if sharedclassroom with calssromm id
    authorize @classroom
    if @classroom.shared?
      # raise
      # get first shared calssroom _id
      shared_classroom = @classroom.shared_classrooms.first
      # assign the sahred_classroom user to curent classroom
      @classroom.user = shared_classroom.user
      @classroom.save
      shared_classroom.destroy
      # destroy shared_class
    else
      @classroom.destroy
    end
    redirect_to classrooms_path
  end

  def results
    authorize @classroom
    @domains =  Domain.where(grade: @classroom.grade).sort_by(&:position)
    @skills = Skill.includes(:domain).where(domain: @domains)
    # @domains.map do |domain|
    #   # remove domains without skills eg:poesie
    #   # @domains.delete(domain) if @skills.none? { |skill| skill.domain == domain }
    # end
    # raise
    respond_to do |format|
      format.html do
        @domain = @domains.first
        @skills = @skills.select { |skill| skill.domain == @domain }.sort
        set_up_results(@domain)
        results_factory(@domain) # create all  variables shared with the results_by_domain Action
      end
      format.xlsx do
        response.headers["Content-Disposition"] = 'attachment; filename="my_new_filename.xlsx"'
        generate_xlsx_file
      end
    end
  end

  def results_by_domain
    authorize @classroom
    # binding.pry
    @domain = Domain.find(set_domain)
    set_up_results(@domain)
    results_factory(@domain) # create all  variables shared with the results Action
    @skills = if @domain.special?
        Skill.where( domain: @domain).order(Arel.sql('COALESCE(sub_domain, \'\') ASC'))
      else
        Skill.where(domain: @domain).sort
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
    params.require(:classroom).permit(:grade_id, :name)
  end

  # COntroller Method

  def generate_xlsx_file
    package = Axlsx::Package.new
    workbook = package.workbook
    header = %w[Ceinture Compétences]
    students_list = @classroom.students.sort_by { |student| student.first_name.downcase }
    header << students_list.map { |student| student.first_name.capitalize }
    # create a tab for each domain
    @domains.each do |domain|
      set_up_results(domain)
      results_factory(domain)
      # all_completed_belts = Belt.includes([:student]).where(student: students_list, domain: domain, completed: true)
      workbook.add_worksheet(name: domain.name.to_s) do |sheet|
        sheet.add_row header.flatten
        @skills.select { |skill| skill.domain == domain }.sort_by { |skill| [skill.level, skill.id] }.each do |skill|
          sheet.add_row create_result_row(skill, students_list).flatten
        end
      end
    end
    send_classroom_results_xlsx(package)
    # Enregistrez le fichier XLSX dans un temp file et envoyez-le en tant que pièce jointe
  end

  def create_result_row(skill, students_list)
    out = [skill.special? ? "" : Belt::BELT_COLORS[skill.level - 1], skill.name]
    out << students_list.map do |student|
      level = skill.special? ? 0 : skill.level
      next unless @all_completed_belts.any? do |belt|
        belt.student == student && belt.domain == skill.domain && belt.level == level
      end ||
                  @all_completed_work_plan_skills[student.id.to_s].to_a.any? do |wps|
                    wps.skill == skill && wps.kind == "ceinture" && wps.completed
                  end

      "X"
    end
    out.flatten
  end

  def send_classroom_results_xlsx(package)
    temp_file = Tempfile.new("temp.xlsx")
    package.serialize(temp_file.path)
    send_file temp_file,
              filename: "#{@classroom.grade.grade_level.upcase}_#{@classroom.name}_resultats_#{Time.zone.today}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  # refacto of result and result_by_domain actions
  def set_up_results(domain)
    # @special_domain = @classroom.user.school.special_domains? && (WorkPlanDomain::DOMAINS_SPECIALS.include?(domain) && @classroom.grade.grade_level != "CM2")
    @students_list = @classroom.students.sort_by { |student| student.first_name.downcase }
    # get all validated belts for all classroom student
    # binding.pry
    @all_completed_belts = Belt.includes([:student]).where(student: @students_list, domain:, completed: true)
  end

  def results_factory(domain)
    # @special_domain = (WorkPlanDomain::DOMAINS_SPECIALS.include?(@domain) && @classroom.grade.grade_level != "CM2")
    @all_completed_work_plan_skills = {}
    @students_list.each do |student|
      # binding.pry if student.id == 393
      completed_wps = student.all_completed_work_plan_skills(domain, @classroom.grade.grade_level)
      @all_completed_work_plan_skills[student.id.to_s] = completed_wps unless completed_wps.empty?
    end
  end
end
