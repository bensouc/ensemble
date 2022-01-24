class ChallengesController < ApplicationController
  def update
    @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
    @challenge = Challenge.find(params[:id])
    if @challenge.update(challenge_params)
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)), notice: 'Excercice Sauvegardé'
    else
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)), notice: "Sauvegarde échouée: #{@challenge.errors.messages}"
    end
  end

  def challenge_params
    params.require(:challenge).permit(:content, :name)
  end
end
