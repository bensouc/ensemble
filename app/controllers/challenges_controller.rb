# frozen_string_literal: true

class ChallengesController < ApplicationController
  before_action :get_work_plan_skill, only: [:clone] #, :update, :show]
  before_action :get_challenge, only: [:clone, :update, :display_challenges, :show, :edit]

  def show
    # respond_to do |format|
    #   format.html do
    #     @work_plan = @work_plan_skill.work_plan_domain.work_plan
    #     render partial: "/challenges/full_challenge_display"
    #   end
    #   format.turbo_stream
    # end
  end

  def edit
  end

  def clone
    new_challenge = @challenge.new_clone
    new_challenge.user = current_user
    new_challenge.save!
    @challenge = new_challenge
    @work_plan_skill.challenge_id = @challenge.id
    @work_plan_skill.save
    # @work_plan = @work_plan_skill.work_plan_domain.work_plan
    # redirect_to @challenge
    render turbo_stream: turbo_stream.replace(@work_plan_skill,
                                              partial: "/work_plan_skills/work_plan_skill_challenge",
                                              locals: { work_plan_skill: @work_plan_skill })
  end

  def update
    if @challenge.update(challenge_params)
      respond_to do |format|
        format.html {
          redirect_to challenge_path(@challenge),
                      notice: "Excercice Sauvegardé"
        }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@challenge,
                                                    partial: "challenges/show_one_challenge",
                                                    locals: { challenge: @challenge })
        end
      end
    else
      redirect_to edit_challenge_path(@challenge), notice: "Sauvegarde échouée "
    end
    # html_update
  end

  def display_challenges
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

  def html_update
    get_work_plan_skill
    if @challenge.update(challenge_params)
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)),
                  notice: "Excercice Sauvegardé"
    else
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)),
                  alert: "Sauvegarde échouée: #{@challenge.errors.messages[:name].first}"
    end
  end

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
