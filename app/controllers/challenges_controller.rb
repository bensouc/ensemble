# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/CyclomaticComplexity

class ChallengesController < ApplicationController
  before_action :set_work_plan_skill, only: [:clone, :display_challenges] # , :update, :show]
  before_action :set_challenge, only: [:clone, :update, :display_challenges, :show, :edit, :destroy]
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
    # binding.pry
    redirect_to classrooms_path if current_user.classrooms.empty? && current_user.shared_classrooms.empty?
    # "/challenges"=>{"grade"=>"CE2", "domain"=>"26", "level"=>"1", "skills"=>"11067"}
    set_filters
    challenges = Challenge.joins(:skill).where(skills: { id: @skills.map(&:id) })
    # binding.pry
    @challenges = challenges.select do |challenge|
      challenge.skill.domain == @domain &&
        challenge.skill.level == @level.to_i && challenge.skill.grade == @grade &&
        !challenge.for_belt?
    end
    @belt_challenges = challenges.select do |challenge|
      challenge.skill.domain == @domain &&
        challenge.skill.level == @level.to_i && challenge.skill.grade == @grade &&
        challenge.for_belt?
    end
    # binding.pry
  end

  def show
    skip_authorization
  end

  def new
    # binding.pry
    @challenge = Challenge.new(user: current_user, skill: Skill.find(params[:skill]))
    @challenge.for_belt = params[:for_belt] == "true"
    @challenge.name = "#{@challenge.skill.name} - #{current_user.first_name} #{(1..100).to_a.sample}"
    @challenge.content = "Écrivez votre énoncé ici"
    authorize @challenge
  end

  def edit
    skip_authorization
  end

  def create
    # binding.pry
    @challenge = Challenge.new(set_challenge_params)
    @challenge.user = current_user
    # binding.pry
    authorize @challenge
    if @challenge.save
      @count = count_challenges
      respond_to do |format|
        format.html { redirect_to challenge_path(@challenge), notice: "Excercice Sauvegardé" }
        format.turbo_stream { flash.now[:notice] = "Excercice Sauvegardé" }
      end
    else
      redirect_to new_challenge_path, notice: "Sauvegarde échouée ", status: :unprocessable_entity
    end
  end

  def update
    # @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
    # authorize @challenge
    skip_authorization
    if @challenge.update(challenge_params)
      respond_to do |format|
        format.html do
          redirect_to challenge_path(@challenge),
                      notice: "Excercice Sauvegardé"
        end
        format.turbo_stream { flash.now[:notice] = "Excercice Sauvegardé" }
      end
    else
      redirect_to edit_challenge_path(@challenge), notice: "Sauvegarde échouée "
    end
    # html_update
  end

  def destroy
    authorize @challenge
    if @challenge.destroy
      @count = count_challenges
      respond_to do |format|
        format.html { redirect_to challenges_path, notice: "Excercice Supprimé" }
        format.turbo_stream
      end
    else
      redirect_to challenges_path, notice: "Cet exercice est attaché à au moins un plan de travail"
    end
  end

  def clone
    # authorize @challenge
    skip_authorization
    new_challenge = @challenge.new_clone
    new_challenge.user = current_user
    new_challenge.save!
    @challenge = new_challenge
    @work_plan_skill.challenge_id = @challenge.id
    @work_plan_skill.save
    # @work_plan = @work_plan_skill.work_plan_domain.work_plan
    # redirect_to @challenge
    respond_to do |format|
      format.html { redirect_to challenge_path(@challenge) }
      format.turbo_stream { flash.now[:notice] = "Excercice cloné" }
    end
  end

  def display_challenges
    skip_authorization
    @challenges = Challenge.includes([:rich_text_content]).where(skill: @challenge.skill).reject do |chal|
      chal == @challenge
    end
    # raise
    if @challenges.empty?
      # @work_plan_skill = WorkPlanSkill.find(@challenge.work_plan_skill_ids.first)
      # @work_plan = @work_plan_skill.work_plan_domain.work_plan
      # render partial: "challenges/challenge_display", notice: "Il n'existe pas d'autre excercice pour cette compétence"
      render turbo_stream: turbo_stream.replace(@challenge,
                                                partial: "challenges/challenge",
                                                locals: { challenge: @challenge })
      flash.now[:notice] = "Il n'existe pas d'autre excercice pour cette compétence"
    else
      respond_to do |format|
        format.html { render partial: "challenges_carroussel" }
        format.turbo_stream
      end
    end
  end

  private

  def count_challenges
    if @challenge.for_belt?
      Challenge.for_belt.where(skill: @challenge.skill).count
    else
      Challenge.classic.where(skill: @challenge.skill).count
    end
  end

  def set_filters
    # binding.pry
    @grades = current_user.classroom_grades
    if params["/challenges"].blank?
      @grade = @grades.first
      @domains = @grade.nil? ? nil : @grade.domains
      @level = 1
      @domain = @domains.first unless @domains.nil?
    else
      @grade = Grade.find(params.require("/challenges").permit(:grade)[:grade])
      @domains = @grade.domains
      @level = params.require("/challenges").permit(:grade, :level, :domain)[:level]
      @domain = Domain.find(params.require("/challenges").permit(:grade, :level, :domain)[:domain])
      # @skill = Skill.find(params.require("/challenges").permit(:skills)[:skills])
      # skill_id = params.require("/challenges").permit(:grade, :level, :domain)[:skills].to_i
    end
    @skills = Skill.where(domain: @domain, level: @level)
  end

  def set_challenge_params
    params.require(:challenge).permit(:skill_id, :content, :name, :for_belt)
  end

  def set_challenge
    @challenge = Challenge.with_rich_text_content_and_embeds.find(params[:id])
  end

  def set_work_plan_skill
    @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
  end

  def challenge_params
    params.require(:challenge).permit(:content, :name, :skill_id, :for_belt)
  end
end
