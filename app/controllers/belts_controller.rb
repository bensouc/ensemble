# frozen_string_literal: true

class BeltsController < ApplicationController
  before_action :set_belt, only: [:edit, :update, :destroy]

  def edit
    authorize @belt
    @skills = @belt.all_skills(current_user)
  end

  def show
    skip_authorization
    @student = Student.find(params[:student_id])
    @domain = Domain.find(params[:id])
    @level = params[:level].to_i
    level = @domain.special? ? 1 : @level
    # binding.pry if @domain.name == "Géométrie" && @level == 2
    @wps_index_to_display = wps_index_to_display(@domain, @level) if @domain.special?
    @skills = @domain.skills.select { |skill| skill.level == level }
    @belt = Belt.find_by(domain: @domain, level: @level, student: @student, completed: true)
    @last_belt = Belt.where(domain: @domain, student: @student, completed: true).order(level: :desc).first
    @results = Result.where(skill: @skills, student: @student, kind: "ceinture", status: "completed")
    @last_wps = WorkPlanSkill.last_wps(@student, @skills)
 raise
  end

  def create
    skip_authorization
    args = new_belt_params
    args[:student_id] = params[:student_id]
    # args[:grade] = Grade.find(new_belt_params[:grade_id])
    args[:domain] = Domain.find(new_belt_params[:domain_id])
    @belt = Belt.find_or_create_by(args)
    @belt.completed = true
    # @belt.student = Student.find(params[:student_id])
    @belt.validated_date = DateTime.now
    if @belt.save
      respond_to do |format|
        format.html { redirect_to student_path(@belt.student) }
        format.turbo_stream
      end
    end
  end

  def update

    # binding.pry
    @belt.validated_date = new_belt_params[:validated_date]
    if @belt.save
      redirect_to student_path(@belt.student)
    else
      redirect_to :edit
    end
  end

  def destroy
    @student = @belt.student
    @domain = @belt.domain
    @level = @belt.level
    @skills = @domain.skills.select { |skill| skill.level == @level }
    @last_wps = WorkPlanSkill.last_wps(@student, @skills)
    @results = Result.where(skill: @skills, student: @student, kind: "ceinture", status: "completed")
    @belt.destroy
    # binding.pry
    respond_to do |format|
      format.html { redirect_to student_path(@belt.student) }
      format.turbo_stream
    end
  end

  private

  def wps_index_to_display(domain, level)
    score = Belt.score_to_validate(domain.grade).find { |hash| hash[:domain] == domain.name }&.dig(:validation)
    start_nb = if level == 1
        0
      else
        score[level - 2] + 1
      end
    end_nb = score[level - 1]
    end_nb = 30 if end_nb.nil?
    {
      score:,
      start_nb:,
      end_nb:
    }
  end

  def set_belt
    @belt = Belt.find(params[:id])
    authorize @belt
  end

  def new_belt_params
    # binding.pry
    params.require(:belt).permit(:domain_id, :level, :validated_date)
  end
end
