# frozen_string_literal: true

class WorkPlanSkillsController < ApplicationController
  def create
    @work_plan_skill = WorkPlanSkill.new(set_params_wpskill)
    @work_plan_skill.student = @work_plan_skill.work_plan_domain.work_plan.student
    challenges = Challenge.where(skill_id: @work_plan_skill.skill)
    if @work_plan_skill.kind.downcase == "exercice"
      if challenges == []
        # if no existing challeng 4 that skill
        # create a empty challenge 4 that skill
        @work_plan_skill.challenge = add_new_chall_2_wps(@work_plan_skill)
      else
        # recuper un des exo existant avec le skill id de @work_plan_skill
        challenge = challenges.sample
        @work_plan_skill.challenge = challenge
      end
    end

    if @work_plan_skill.save! && @work_plan_skill.kind.downcase == "exercice"
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan,
                                 anchor: helpers.dom_id(@work_plan_skill.challenge))
    elsif @work_plan_skill.save!
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan,
                                 anchor: helpers.dom_id(@work_plan_skill.work_plan_domain))
      # a revoir poour la failedsaveredirection
    else
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan)
    end
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
    # if format nil => no evaluation
    if params[:format].nil? || !params[:challenge].nil?
      @challenge = Challenge.find(params[:challenge])
      @work_plan_skill.challenge = @challenge
      @work_plan_skill.save!
      redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan, anchor: helpers.dom_id(@challenge))
      return
    end
    # :format completed redo failed
    @work_plan_skill.status = params[:format]
    # Create a belt or get the corresponding one
    belt = Belt.find_or_create_by(
      {
        student_id: @work_plan_skill.student.id,
        domain: @work_plan_skill.work_plan_domain.domain,
        grade: @work_plan.grade,
        level: @work_plan_skill.work_plan_domain.level,
      }
    )
    # add test if (@work_plan_skill.kind == 'ceinture' && @work_plan_skill.status)
    if @work_plan_skill.kind == "ceinture" || @work_plan_skill.kind == "controle"
      case @work_plan_skill.status
      when "completed"
        @work_plan_skill.completed = true
        # test for each skill of its domain a 'belt is validated'jbiv
        @work_plan_skill.save
        if WorkPlanDomain::DOMAINS_SPECIALS.include?(@work_plan_skill.work_plan_domain.domain)
          Belt.special_newbelt(@work_plan_skill, @work_plan)
        elsif @work_plan_skill.work_plan_domain.all_skills_completed?
          belt.completed = true
          belt.validated_date = Time.zone.now
          belt.save
        end
      end
    end

    @work_plan_skill.save
    if is_mobile_device?
      redirect_to mobile_eval_path(@work_plan_skill.work_plan_domain.work_plan,
                                   anchor: helpers.dom_id(@work_plan_skill.work_plan_domain))
    else
      redirect_to eval_path(@work_plan_skill.work_plan_domain.work_plan,
                            anchor: helpers.dom_id(@work_plan_skill.work_plan_domain))
    end
  end

  private

  def set_params_wpskill
    {
      work_plan_domain_id: params.require(:work_plan_domain_id),
      skill_id: params.require(:skill).to_i,
      kind: params.require(:kind),
      status: "new",
    }
  end

  def add_new_chall_2_wps(work_plan_skill)
    name = work_plan_skill.skill.name + (Challenge.where(skill_id: work_plan_skill.skill).count + 1).to_s
    Challenge.create_empty(work_plan_skill, name, current_user)
    # @work_plan_skill.challenge = challenge
  end
end
