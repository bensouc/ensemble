# frozen_string_literal: true

class ChallengesController < ApplicationController
  before_action :get_work_plan_skill, only: [:clone, :update]
  before_action :get_challenge, only: [:clone, :update]

  def clone
    @new_challenge = @challenge.new_clone
    @new_challenge.user = current_user
    @new_challenge.save!
    @work_plan_skill.challenge_id = @new_challenge.id
    @work_plan_skill.save
    respond_to do |format|
      format.html {
        redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)),
                    notice: "Clonage réussi"
      }
      format.json { render @challenge }
    end
  end

  def update
    # @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])

    if @challenge.update(challenge_params)
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)),
                  notice: "Excercice Sauvegardé"
    else
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)),
                  alert: "Sauvegarde échouée: #{@challenge.errors.messages[:name].first}"
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
