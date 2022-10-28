# frozen_string_literal: true

class WorkPlanDomainsController < ApplicationController
  def create
    @work_plan = WorkPlan.find(params_wp_id)
    @domain = WorkPlanDomain.new(domain: work_plan_domain_params[:domain], level: work_plan_domain_params[:level]) # remove, student: @work_plan.student
    kind = params.require(:kind)
    @domain.work_plan = @work_plan
    @domain.save!

    if WorkPlanDomain::DOMAINS_SPECIALS.include?(@domain.domain)
      @domain.level = 1
    else
      # recupere les skills associé domaine/level dnas un tableau
      skills = Skill.where(domain: @domain.domain, level: @domain.level, grade: @work_plan.grade)
      # loop autour du tableau des skills du domain/level
      ######################### SKILLS loop START ######################
      skills&.each do |skill|
        work_plan_skill = WorkPlanSkill.new(
          work_plan_domain_id: @domain.id,
          skill_id: skill.id,
          kind: kind
          # REMOVE student: @work_plan.student
        )
        if kind == "exercice"
          ############### refacto START add_challenges_2_wps############
          # challenge = add_challenges_2_wps(work_plan_skill)
          challenge = work_plan_skill.add_challenges_2_wps(current_user)
          ############ refacto END ############
          work_plan_skill.challenge = challenge
        end
        work_plan_skill.save!
      end
      ######################### SKILLS loop END ######################
    end
    if @domain.save
      redirect_to work_plan_path(@work_plan, anchor: "bottom")
    else
      redirect_to work_plan_path(@work_plan, anchor: "dmn-validate")
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

  # def add_challenges_2_wps(work_plan_skill)
  #   challenges = Challenge.where(skill_id: work_plan_skill.skill)
  #   if challenges == []
  #     # if no existing challeng 4 that skill
  #     # create a empty challenge 4 that skill
  #     name = work_plan_skill.skill.name + (challenges.count + 1).to_s
  #     challenge = Challenge.create_empty(work_plan_skill, name, current_user)
  #   else
  #     # recuper un des exo existant avec le skill id de @work_plan_skill
  #     challenge = challenges.sample
  #   end
  #   return challenge
  # end
end
