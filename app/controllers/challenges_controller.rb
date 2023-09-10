# frozen_string_literal: true

class ChallengesController < ApplicationController
  before_action :get_work_plan_skill, only: [:clone, :update, :show]
  before_action :get_challenge, only: [:clone, :update, :display_challenges, :show]

  def show
    @work_plan = @work_plan_skill.work_plan_domain.work_plan
    # authorize @challenge
    skip_authorization
    render partial: "/challenges/full_challenge_display"
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
    @work_plan = @work_plan_skill.work_plan_domain.work_plan
    render partial: "/challenges/full_challenge_display"
  end

  def update
    # @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
    # authorize @challenge
    skip_authorization
    if @challenge.update(challenge_params)
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)),
                  notice: "Excercice Sauvegardé"
    else
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)),
                  alert: "Sauvegarde échouée: #{@challenge.errors.messages[:name].first}"
    end
  end

  def display_challenges
    # authorize @challenge
    skip_authorization
    @challenges = Challenge.where(skill: @challenge.skill).reject { |chal| chal == @challenge }
    # raise
    if @challenges.empty?
      # @work_plan_skill = WorkPlanSkill.find(@challenge.work_plan_skill_ids.first)
      # @work_plan = @work_plan_skill.work_plan_domain.work_plan
      # render partial: "challenges/challenge_display", notice: "Il n'existe pas d'autre excercice pour cette compétence"
      flash.now[:notice] = "Il n'existe pas d'autre excercice pour cette compétence"
    else
      render partial: "challenges/challenges_carroussel"
    end
  end

  private

  def get_challenge
    @challenge = Challenge.find(params[:id])
  end

  def get_work_plan_skill
    @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
  end

  def challenge_params
    params.require(:challenge).permit(:content, :name)
  end
end
