class WorkPlanDomainsController < ApplicationController
  def create
    @work_plan = WorkPlan.find(params_wp_id)
    @domain = WorkPlanDomain.new(work_plan_domain_params)
    kind = params.require(:kind)
    @domain.work_plan = @work_plan
    @domain.save!
    if ["Géométrie", "Grandeurs et Mesures"].include?(@domain.domain)
      @domain.level = 1
      if @domain.save
        redirect_to work_plan_path(@work_plan, anchor: "bottom")
      else
        redirect_to work_plan_path(@work_plan, anchor: "dmn-validate")
      end
    else
      ######################### start loop
      # recupere les skills associé domaine/level dnas un tableau
      skills = Skill.where(domain: @domain.domain, level: @domain.level)
      # loop autour du tableau des skills du domain/level
      skills.each do |skill|
        # à chaque loop, creer wokrplan skill.
        work_plan_skill = WorkPlanSkill.new(
          work_plan_domain_id: @domain.id,
          skill_id: skill.id,
          kind: kind
        )
        if kind == "exercice"
          challenges = Challenge.where(skill_id: skill)
          if challenges == []
            # if no existing challeng 4 that skill
            # create a empty challenge 4 that skill
            name = work_plan_skill.skill.name + ((Challenge.where(skill_id: work_plan_skill.skill).count) + 1).to_s
            challenge = Challenge.create(
              {
                skill: work_plan_skill.skill,
                name: name,
                user: current_user,
              }
            )
            challenge.content.body = <<~HTML
              Exercice à REDIGER............................
            HTML
            challenge.save!
            # @work_plan_skill.challenge = challenge
          else
            # recuper un des exo existant avec le skill id de @work_plan_skill
            challenge = challenges.sample
          end
          work_plan_skill.challenge = challenge
        end
        work_plan_skill.save!
      end
      # $$$$$$$ END $$$$$$$$$$$$$$$$$$$$
      if @domain.save
        redirect_to work_plan_path(@work_plan, anchor: "bottom")
      else
        redirect_to work_plan_path(@work_plan, anchor: "dmn-validate")
      end
    end
  end

  def destroy
    @work_plan_domain = WorkPlanDomain.find(params[:id])
    # raise
    @work_plan_domain.destroy
    redirect_to work_plan_path(@work_plan_domain.work_plan)
  end

  private

  def params_wp_id
    params.require(:work_plan_id)
  end

  def work_plan_domain_params
    params[:work_plan].require(:work_plan_domain).permit(:domain, :level)
  end

  def work_plan_domain_kind_params
    params.require(:kind)
  end
end
