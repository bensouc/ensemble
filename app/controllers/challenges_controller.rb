class ChallengesController < ApplicationController
  def clone
    @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
    @challenge = Challenge.new_clone(Challenge.find(params[:id]))
    @challenge.user = current_user
    @challenge.save!
    @work_plan_skill.challenge_id = @challenge.id
    @work_plan_skill.save
    redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)), notice: 'Clonage réussi'
  end

  def update
    @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
    @challenge = Challenge.find(params[:id])
    if @challenge.update(challenge_params)
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)), notice: 'Excercice Sauvegardé'
    else
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge)), notice: "Sauvegarde échouée: #{@challenge.errors.messages}"
    end
  end

  private

  def challenge_params
    params.require(:challenge).permit(:content, :name)
  end
end
