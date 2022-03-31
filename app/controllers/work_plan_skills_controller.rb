class WorkPlanSkillsController < ApplicationController

  def create

    @work_plan_skill = WorkPlanSkill.new(set_params_wpskill)
    challenges = Challenge.where(skill_id: @work_plan_skill.skill)
    if (@work_plan_skill.kind.downcase == 'exercice')
      if challenges == []
        # if no existing challeng 4 that skill
        # create a empty challenge 4 that skill
        name = @work_plan_skill.skill.name + ( (Challenge.where(skill_id: @work_plan_skill.skill).count) +1  ).to_s
        challenge = Challenge.create({
            skill: @work_plan_skill.skill,
            name: name,
            user: current_user
          } )
        challenge.content.body = <<~HTML
        Exercice à REDIGER............................
        HTML
        challenge.save!
        # @work_plan_skill.challenge = challenge
      else
        # recuper un des exo existant avec le skill id de @work_plan_skill
        challenge = challenges.sample

      end
      @work_plan_skill.challenge = challenge
    end

    if @work_plan_skill.save! && @work_plan_skill.kind.downcase == 'exercice'
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(challenge))
    elsif @work_plan_skill.save!
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@work_plan_skill.work_plan_domain))
      # a revoir poour la failedsaveredirection
    else
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan)
    end
  end


  def update_eval
   @work_plan_skill = WorkPlanSkill.find(params[:id])
   raise
   #input : completed / failed / redo

  end


  def destroy
    @work_plan_skill = WorkPlanSkill.find(params[:id])
    work_plan_domain = @work_plan_skill.work_plan_domain
    # raise
    @work_plan_skill.destroy
    redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(work_plan_domain))
  end

  def update
    @work_plan_skill = WorkPlanSkill.find(params[:id])
    @work_plan = @work_plan_skill.work_plan_domain.work_plan
    if params[:format].nil?
      @challenge = Challenge.find(params[:challenge])
      @work_plan_skill.challenge = @challenge
      @work_plan_skill.save
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge))
    end

    @work_plan_skill.status = params[:format]
    @work_plan_skill.save
    redirect_to eval_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@work_plan_skill.work_plan_domain))
  end



  private

  def set_params_wpskill
    {
      work_plan_domain_id: params.require(:work_plan_domain_id),
      skill_id: params.require(:skill).to_i,
      kind: params.require(:kind)
    }
  end


end
