class ChallengesController < ApplicationController
  def update
    @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
    @challenge = Challenge.find(params[:id])
    @challenge.update(challenge_params)
        redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge))
  end

  def challenge_params
    params.require(:challenge).permit(:content)
  end
end
