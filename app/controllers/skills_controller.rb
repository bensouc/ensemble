# frozen_string_literal: true

class SkillsController < ApplicationController
  before_action :set_skill, only: [:show, :edit, :update, :destroy]
  before_action :setup_all_skills_data, only: [:index]
  before_action :set_uploaded_file_path, only: [:add_skills_from_xls]
  before_action :set_xls_file_path, only: [:upload_skills_xlsx]
  # before_action :setup_all_skills_data, only: [:index]
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
    redirect_to classrooms_path unless current_user.classroom?
    # setup_all_skills_data
    respond_to do |format|
      format.html { setup_all_skills_data }
      format.xlsx do
        grade = Grade.includes([:domains, :skills]).find(params[:grade])
        skills = grade.skills
        domains = grade.domains.sort_by(&:position)
        school = current_user.school
        response.headers["Content-Disposition"] = 'attachment; filename="my_new_filename.xlsx"'
        package = Xlsx.skills_generate_xlsx_file(school, grade, domains, skills)
        send_xlsx_file(package, school, grade)
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
    @skill = Skill.new(skill_params)
    # @skill.grade = Grade.find(set_grade)
    @skill.school = current_user.school
    @skill.save!
    # redirect_to skill_path(@skill)
    @skills = Skill.includes([:school]).where(domain: @skill.domain, level: @skill.level)

    respond_to  do |format|
      format.html { redirect_to skills_path}
      format.turbo_stream
    end


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
    # Ajoutez ici le code pour traiter le fichier Excel
    sheets = Xlsx.parse_xlsx_file(@uploaded_file_path)
    # add test if file is OK
    temp_skills = Skill.sheets_to_temp_skills_creation(sheets, @grade, current_user, @grade.domains)
    # create new set of skills
    new_skills = Skill.create_loaded_skills(temp_skills[:skills])
    # Supprimez le fichier après le traitement
    File.delete(@uploaded_file_path) if File.exist?(@uploaded_file_path)
    # puts "SKILL XLS UPLOAD REUSSI"
    if temp_skills[:errors].empty?
    flash[:success] = "#{temp_skills[:skills].count} Compétences ajoutées"
      redirect_to skills_path
    else
      @errors = temp_skills[:errors]
      flash[:error] = "vous avez des euurers"
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
      flash[:error] = "Please choose a file to upload."
      redirect_to skills_path
    end
  end

  private

  def setup_all_skills_data
    @grades = current_user.classroom_grades
    grade_query = params[:grade]
    domain_query = params[:domain]
    @school = current_user.school
    @grade = grade_query.nil? ? @grades.first : Grade.find(grade_query)
    unless @grade.nil?
      @domains = @grade.domains.nil? ? nil : @grade.domains.sort_by(&:position)
      # binding.pry
      @domain = domain_query.nil? ? @domains.first : Domain.find(domain_query)
    end
    # @skills = policy_scope(Skill)
    # @are_special_domains = current_user.school.special_domains?
    @skills = Skill.where(domain: @domain)
  end

  def set_skill
    @skill = Skill.find(params[:id])
  end

  def set_grade
    params.require(:skill).permit(:grade)
  end

  def skill_params
    params.require(:skill).permit(:name, :symbol, :level, :domain_id)
  end

  # get xlsx url for upload_skills
  def set_uploaded_file_path
    @uploaded_file_path = session[:uploaded_file_path]
    @grade = Grade.includes(:domains).find(session[:grade_id])
    # @old_skills = Skill.where(grade: @grade)
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
