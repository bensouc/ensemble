# frozen_string_literal: true

class WorkPlanDomainsController < ApplicationController
  def new
    @work_plan = WorkPlan.find(params_wp_id)
    authorize @work_plan
    @domains = @work_plan.all_domains_from_work_plan
  end

  def show
    @work_plan_domain = WorkPlanDomain.includes(:work_plan).find(params[:id])
    authorize @work_plan_domain
  end

  def create
    @work_plan = WorkPlan.find(params_wp_id)
    authorize @work_plan
    @domain = WorkPlanDomain.new(domain: work_plan_domain_params[:domain], level: work_plan_domain_params[:level]) # remove, student: @work_plan.student
    kind = params.require(:kind)
    @domain.work_plan = @work_plan
    @domain.save!
    student = @work_plan.student
    # test if work_plan.grade == "CM2" no special dmoains AND no domains specials for other grades
    # is_domain_special = (@work_plan.grade != "CM2" && @domain.specials?)
    is_domain_special = @domain.specials?
    is_belt_validated = student.nil? ? false : student.belt_status(@domain.domain, @domain.level)
    if is_domain_special
      @domain.level = 1
    elsif !is_belt_validated
      # binding.pry
      # recupere les skills associé domaine/level dnas un tableau
      skills = Skill.for_school(current_user.school).where(domain: @domain.domain, level: @domain.level, grade: @work_plan.grade)
      # binding.pry
      # loop autour du tableau des skills du domain/level
      ######################### SKILLS loop START ######################
      skills&.each do |skill|
        # unless kind is 'exercice' and student.skill_status(skill) == 'skill_status_belt'
        current_skill_status = student.skill_status(skill, kind) unless student.nil?
        # binding.pry
        unless current_skill_status == "skill_status_completed" || (kind == "exercice" && current_skill_status == "skill_status_belt")
          work_plan_skill = WorkPlanSkill.new(
            work_plan_domain_id: @domain.id,
            skill_id: skill.id,
            kind: kind,
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
      end
      ######################### SKILLS loop END ######################
    end
    if @domain.work_plan_skills.count.zero? && !is_domain_special
      @domain.destroy
      redirect_to work_plan_path(@work_plan), notice: "Il n'est plus d'exercice ou de ceinture non validé pour cette couleur"
    elsif @domain.save!
      respond_to do |format|
        format.html { redirect_to work_plan_path(@work_plan, anchor: "bottom") }
        format.turbo_stream
      end
    else
      redirect_to work_plan_path(@work_plan, anchor: "dmn-validate")
    end
  end

  def update
    @work_plan_domain = WorkPlanDomain.find(params[:id])
  end

  def destroy
    @work_plan_domain = WorkPlanDomain.find(params[:id])
    # raise
    authorize @work_plan_domain
    @work_plan_domain.destroy
    respond_to do |format|
      format.html { redirect_to work_plan_path(@work_plan, anchor: "bottom") }
      format.turbo_stream
    end
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
  #   challenges = Challenge.classic.where(skill_id: work_plan_skill.skill)
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
