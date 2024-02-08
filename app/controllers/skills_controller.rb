# frozen_string_literal: true

class SkillsController < ApplicationController
  before_action :set_skill, only: [:show, :edit, :update, :destroy]
  before_action :setup_all_skills_data, only: [:index]
  before_action :set_uploaded_file_path, only: [:add_skills_from_xls]
  before_action :set_xls_file_path, only: [:upload_skills_xlsx]

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
    @grades = current_user.classroom_grades
    @skill = Skill.new
  end

  def edit
    authorize @skill
  end

  def create
    skip_authorization
    # binding.pry
    @skill = Skill.new(skill_params)
    # @skill.grade = Grade.find(set_grade)
    @skill.school = current_user.school
    @skill.save!
    # redirect_to skill_path(@skill)
    @skills = Skill.includes([:grade, :school]).where(grade: @skill.grade, school: current_user.school, domain: @skill.domain, level: @skill.level)
    render partial: "skills/all_skills_by_domain_level",
           locals: { skills: @skills, domain: @skill.domain, level: @skill.level, grade: @skill.grade }

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

  def add_skills_from_xls
    # Code de la méthode parse_xlsx_file
    authorize Skill
    if @uploaded_file_path.present?
      # Ajoutez ici le code pour traiter le fichier Excel
      sheets = Xlsx.parse_xlsx_file(@uploaded_file_path)
      # add test if file is OK
      temp_skills = Skill.sheets_to_temp_skills_creation(sheets, @grade, current_user)
      raise
      # Supprimez le fichier après le traitement
      File.delete(@uploaded_file_path) if File.exist?(@uploaded_file_path)

      # puts "SKILL XLS UPLOAD REUSSI"
      flash[:success] = "File processed successfully!"
      redirect_to skills_path
    else
      flash[:error] = "No uploaded file found."
      redirect_to skills_path
    end
  end

  def upload_skills_xlsx
    authorize Skill
    if @xls_file_path
      file_path = Rails.root.join("tmp", @xls_file_path.original_filename)
      File.open(file_path, "wb") { |file| file.write(@xls_file_path.read) }
      # Stockez le chemin du fichier dans la session
      session[:uploaded_file_path] = file_path.to_s
      session[:grade_id] = params[:liste][:level]
      # flash[:success] = "File uploaded successfully!"
      redirect_to add_skills_from_xls_path, params: {grade: params[:liste][:level] }
    else
      # flash[:error] = "Please choose a file to upload."
      redirect_to skills_path
    end
  end

  private

  def setup_all_skills_data
    # @grades = current_user.classroom_grades
    # @grades = Classroom::GRADE.select { |grade| current_user.classroom_grades.include?(grade.grade_level) }
    @grades = current_user.classroom_grades
    query = params[:grade]

    @school = current_user.school
    @grade = query.nil? ? @grades.first : Grade.find(query)
    @skills = policy_scope(Skill)
    @are_special_domains = current_user.school.special_domains?
    @skills = @skills.select { |skill| skill.grade == @grade }
  end

  def set_skill
    @skill = Skill.find(params[:id])
  end

  def set_grade
    params.require(:skill).permit(:grade)
  end

  def skill_params
    params.require(:skill).permit(:name, :grade_id, :symbol, :level, :domain)
  end

  # get xlsx url for uplaod_skills
  def set_uploaded_file_path
    @uploaded_file_path = session[:uploaded_file_path]
    @grade = Grade.find(session[:grade_id])
  end

  def set_xls_file_path
    @xls_file_path = params[:liste][:excel_file]
  end

  # XLSX GENERATION and send
  def send_xlsx_file(package, school, grade)
    temp_file = Tempfile.new("temp.xlsx")
    package.serialize(temp_file.path)
    send_file temp_file,
              filename: "#{school.name.upcase}_#{grade.name}_compétences_#{Time.zone.today}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end
end
