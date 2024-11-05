# frozen_string_literal: true

class BeltsController < ApplicationController
  before_action :set_belt, only: [:edit, :update, :destroy]

  def show
    skip_authorization
    @student = Student.find(params[:student_id])
    @domain = Domain.find(params[:id])
    @level = params[:level].to_i
    # binding.pry if @domain.name == "Géométrie" && @level == 2
    set_data_show
    #  raise
  end

  def edit
    authorize @belt
    @skills = @belt.all_skills(current_user)
  end

  def create
    skip_authorization
    args = new_belt_params
    args[:student_id] = params[:student_id]
    # args[:grade] = Grade.find(new_belt_params[:grade_id])
    args[:domain] = Domain.find(new_belt_params[:domain_id])
    @belt = Belt.find_or_create_by(args)
    @belt.completed!
    # @belt.student = Student.find(params[:student_id])
    if @belt.save
      @domain = @belt.domain
      @student = @belt.student
      @level = @belt.level
      set_data_show
      respond_to do |format|
        format.html { redirect_to student_path(@belt.student) }
        format.turbo_stream
      end
    else
      redirect_to student_path(@belt.student)
    end
  end

  def update
    @belt.validated_date = new_belt_params[:validated_date]
    @domain = @belt.domain
    @student = @belt.student
    @level = @belt.level
    if @belt.save
      set_data_show
      respond_to do |format|
        format.html { redirect_to student_path(@student) }
        format.turbo_stream
      end
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
    redirect_to student_path(@belt.student) if @domain.special?
    respond_to do |format|
      set_data_show
      format.html { redirect_to student_path(@belt.student) }
      format.turbo_stream
    end
  end

  private

  def set_data_show
    level = @domain.special? ? 1 : @level
    @skills = @domain.skills.select { |skill| skill.level == level }
    @results = Result.where(skill: @skills, student: @student, kind: "ceinture", status: "completed")
    @belt = Belt.find_by(domain: @domain, level: @level, student: @student, completed: true)
    @last_belt = Belt.where(domain: @domain, student: @student, completed: true).order(level: :desc).first
    @last_wps = WorkPlanSkill.last_wps(@student, @skills)
  end

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
      end_nb:,
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
