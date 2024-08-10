# frozen_string_literal: true

class WorkPlanDomainsController < ApplicationController
  def show
    @work_plan_domain = WorkPlanDomain.includes(:work_plan).find(params[:id])
    authorize @work_plan_domain
  end

  def new
    @work_plan = WorkPlan.find(params_wp_id)
    authorize @work_plan
    @domains = @work_plan.grade.domains.sort_by(&:position)
    @special = @domains.any?{|domain| domain.special?}
  end

  def create
    @work_plan = WorkPlan.find(params_wp_id)
    authorize @work_plan
    @domain = Domain.find(work_plan_domain_params[:domain])
    @work_plan_domain = WorkPlanDomain.new(domain: @domain, level: work_plan_domain_params[:level].to_i) # remove, student: @work_plan.student
    kind = params.require(:kind)
    @work_plan_domain.work_plan = @work_plan
    @work_plan_domain.save!
    student = @work_plan.student
    # test if work_plan.grade == "CM2" no special dmoains AND no domains specials for other grades
    # is_domain_special = (@work_plan.grade != "CM2" && @work_plan_domain.special?)
    is_domain_special = @domain.special?
    is_belt_validated = student.nil? ? false : student.belt_status(@work_plan_domain.domain, @work_plan_domain.level)
    if is_domain_special
      @work_plan_domain.level = 1
    elsif !is_belt_validated
      # binding.pry
      # recupere les skills associé domaine/level dnas un tableau
      skills = Skill.where(domain: @work_plan_domain.domain, level: @work_plan_domain.level)
      # binding.pry
      # loop autour du tableau des skills du domain/level
      ######################### SKILLS loop START ######################
      skills&.each do |skill|
        # unless kind is 'exercice' and student.skill_status(skill) == 'skill_status_belt'
        result = Result.find_or_create_by(skill:, student:) unless student.nil?
        unless !student.nil? && (result.belt_validated? || (kind == "exercice" && result.challenge_validated?))
          work_plan_skill = WorkPlanSkill.new(
            work_plan_domain_id: @work_plan_domain.id,
            skill_id: skill.id,
            kind:
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
    @work_plan_skills = @work_plan_domain.work_plan_skills
    if @work_plan_skills.count.zero? && !is_domain_special
      @work_plan_domain.destroy
      redirect_to work_plan_path(@work_plan),
                  notice: "Il n'y a plus d'exercice ou de ceinture non validé pour cette couleur"
    elsif @work_plan_domain.save!
      respond_to do |format|
        format.html { redirect_to work_plan_path(@work_plan, anchor: "bottom") }
        format.turbo_stream { flash.now[:notice] = "Domaine ajouté" }
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


end
