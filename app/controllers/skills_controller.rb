# frozen_string_literal: true

class SkillsController < ApplicationController
  before_action :set_skill, only: [:show, :edit, :update, :destroy]
  before_action :setup_all_skills_data, only: [:index]

  def index
    redirect_to classrooms_path unless current_user.classroom?
    # setup_all_skills_data
    respond_to do |format|
      format.html
      format.xlsx do
        response.headers["Content-Disposition"] = 'attachment; filename="my_new_filename.xlsx"'
        package = Xlsx.skills_generate_xlsx_file(@school, @grade, @skills)
        send_xlsx_file(package, @school, @grade)
      end
    end
    # for production => "A fournier == "
    # @are_special_domains = current_user.school.id == 1
  end

  def show
    authorize @skill
  end

  def new
    @skill = Skill.new
  end

  def edit
    authorize @skill
  end

  def create
    skip_authorization
    @skill = Skill.new(skill_params)
    @skill.school = current_user.school
    @skill.save!
    # redirect_to skill_path(@skill)
    @skills = Skill.where(grade: @skill.grade, school: current_user.school, domain: @skill.domain, level: @skill.level)
    render partial: "skills/all_skills_by_domain_level",
           locals: { skills: @skills, domain: @skill.domain, level: @skill.level }

    #  skills: skills, domain: domain, level: skill_level
  end

  def update
    authorize @skill
    @skill.update!(skill_params)
    redirect_to skill_path(@skill)
  end

  def destroy
    authorize @skill
    begin
      @skill.destroy
      respond_to do |format|
        format.html { redirect_to skills_path, notice: "Compétence effacée" }
        format.turbo_stream
      end
    rescue ActiveRecord::InvalidForeignKey => e
      render partial: "skills/destroy_error", locals: { skill: @skill }
    end
    # redirect_to skills_path
  end

  private

  def setup_all_skills_data
    # @grades = current_user.classroom_grades
    @grades = Classroom::GRADE.select { |grade| current_user.classroom_grades.include?(grade) }
    query = params[:grade]
    @school = current_user.school
    @grade = query.nil? ? @grades.first : query
    @skills = policy_scope(Skill)
    @are_special_domains = current_user.school.id == 1
    @skills = @skills.select { |skill| skill.grade == @grade }
  end

  def set_skill
    @skill = Skill.find(params[:id])
  end

  def skill_params
    params.require(:skill).permit(:name, :grade, :symbol, :level, :domain)
  end

  # XLSX GENERATION and send
  def send_xlsx_file(package, school, grade)
    temp_file = Tempfile.new("temp.xlsx")
    package.serialize(temp_file.path)
    send_file temp_file,
              filename: "#{school.name.upcase}_#{grade}_compétences_#{Time.zone.today}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end
end
