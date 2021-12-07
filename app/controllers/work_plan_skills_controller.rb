class WorkPlanSkillsController < ApplicationController

  def create

    @work_plan_skill = WorkPlanSkill.new(set_params_wpskill)

    if @work_plan_skill.kind.downcase == 'exercice'
      name = @work_plan_skill.skill.name + ( (Challenge.where(skill_id: @work_plan_skill.skill).count) +1  ).to_s
      challenge = Challenge.create({
        skill: @work_plan_skill.skill,
        name: name,
        user: current_user
      })
      challenge.content.body = <<~HTML
      A vous de jouer
      HTML
      challenge.save!
      @work_plan_skill.challenge = challenge
    end

    if @work_plan_skill.save!
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan)
    else
      # a revoir poour la failedsaveredirection
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan)
    end
  end

  #u^date
  #recupere l'id du nouveau challenge
  #re^lace l'id du challenege par le nouve
  # @sauver


  private

  def set_params_wpskill
    {
      work_plan_domain_id: params.require(:work_plan_domain_id),
      skill_id: params.require(:skill).to_i,
      kind: params.require(:kind)
    }
  end
end
