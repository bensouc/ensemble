# frozen_string_literal: true

class SkillsController < ApplicationController
  before_action :set_skill, only: [:show, :edit, :update, :destroy]

  def index
    @grades = current_user.classroom_grades
    query = params[:grade]
    @grade = if query.nil?
        @grades.first  # gérer la query later ici
      else
        query
      end
    @skills = Skill.includes([:challenges]).for_school(current_user.school)
    @are_special_domains = current_user.school.id == 1
    @skills = @skills.select { |skill| skill.grade == @grade }
    # for production => "A fournier == "
    # @are_special_domains = current_user.school.id == 1
  end

  def show
  end

  def new
    @skill = Skill.new
  end

  def edit
  end

  def create
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
    @skill.update!(skill_params)
    redirect_to skill_path(@skill)
  end

  def destroy
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

  # private
  def set_skill
    @skill = Skill.find(params[:id])
  end

  def skill_params
    params.require(:skill).permit(:name, :grade, :symbol, :level, :domain)
  end
end
