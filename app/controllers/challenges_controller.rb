class ChallengesController < ApplicationController

  def clone
    puts "Clone launched"
    @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
    challenge_mom = Challenge.find(params[:id])

    @challenge = Challenge.new(
      {
        name: "#{challenge_mom.name}-Clone#{rand(1..10)}",
        content: challenge_mom.content,
        skill_id: challenge_mom.skill_id
      }
    )
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
