# frozen_string_literal: true

class WorkPlanSkillsController < ApplicationController
  def show
    @work_plan_skill = WorkPlanSkill.includes([:challenge, :skill]).find(params[:id])
    @alone = Challenge.where(skill: @work_plan_skill.skill).count.zero?
    authorize @work_plan_skill
  end

  def create
    @work_plan_skill = WorkPlanSkill.new(set_params_wpskill)
    authorize @work_plan_skill
    # @work_plan_skill.student = @work_plan_skill.work_plan_domain.work_plan.student
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
    if @work_plan_skill.save!
      respond_to do |format|
        format.html {
          redirect_to work_plan_domain_path(@work_plan_skill.work_plan_domain),
                      notice: "Modification Sauvegardée"
        }
        format.turbo_stream
      end
    else
      redirect_to work_plan_skill_path(@work_plan_skill), notice: "Sauvegarde échouée "
    end

    # if @work_plan_skill.save! && @work_plan_skill.kind.downcase == "exercice"
    #   redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan,
    #                              anchor: helpers.dom_id(@work_plan_skill.challenge))
    # elsif @work_plan_skill.save!
    #   redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan,
    #                              anchor: helpers.dom_id(@work_plan_skill.work_plan_domain))
    #   # a revoir poour la failedsaveredirection
    # else
    #   redirect_to work_plan_path(@work_plan_skill.work_plan_domain.work_plan)
    # end
  end

  def update
    @work_plan_skill = WorkPlanSkill.find(params[:id])
    # binding.pry
    authorize @work_plan_skill
    @work_plan_skill.challenge = Challenge.find(set_params_wpskill_challenge)

    if @work_plan_skill.save!
      respond_to do |format|
        format.html {
          redirect_to work_plan_skill_path(@work_plan_skill),
                      notice: "Modification Sauvegardée"
        }
        format.turbo_stream
      end
    else
      redirect_to work_plan_skill_path(@work_plan_skill), notice: "Sauvegarde échouée "
    end
  end

  def destroy
    @work_plan_skill = WorkPlanSkill.find(params[:id])
    authorize @work_plan_skill
    @work_plan_domain = @work_plan_skill.work_plan_domain
    # raise
    @work_plan_skill.destroy
    respond_to do |format|
      format.html {
        redirect_to work_plan_path(work_plan_domain.work_plan),
                    notice: "Modification Sauvegardée"
      }
      format.turbo_stream
    end
  end

  def eval_update
    # binding.pry
    @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
    authorize @work_plan_skill
    @work_plan = @work_plan_skill.work_plan_domain.work_plan
    #  binding.pry

    @work_plan_skill.status = params[:status]
    # @work_plan_skill.completed = true if @work_plan_skill.kind == "ceinture" && params[:status] == "completed"
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
        @work_plan_skill.save!

        # test for each skill of its domain a 'belt is validated'jbiv
        # if @work_plan_skill.work_plan_domain.specials? && @work_plan.grade != "CM2"
        if @work_plan_skill.work_plan_domain.specials? #ADD management for ALAIN FOURNIER
          Belt.special_newbelt(@work_plan_skill, @work_plan)
        elsif @work_plan_skill.work_plan_domain.all_skills_completed?
          belt.completed = true
          belt.validated_date = DateTime.now
          belt.save!
        end
      end
    end

    @work_plan_skill.save!
    render partial: "work_plans/eval_last_wps_ajax"
  end

  def change_challenge
    # binding.pry
    @work_plan_skill = WorkPlanSkill.find(params[:work_plan_skill_id])
    authorize @work_plan_skill
    @work_plan = @work_plan_skill.work_plan_domain.work_plan
    @challenge = Challenge.find(params[:challenge])
    @work_plan_skill.challenge = @challenge
    @work_plan_skill.save!
    render partial: "/challenges/full_challenge_display"
  end

  # to add a validated wps on a student on special_wps=true Workplan
  def add_validated_wps
    skip_authorization
    skills_and_student = get_all_skills_to_add_completed_wps #call private method to get all the needed skills to be completed
    skills = skills_and_student[:skills]
    domain = skills.first.domain # get domain to work on
    @student = skills_and_student[:student] # get the student
    # student_grade = skills.first.grade # the grade to work on
    # find or create the student special work_pal vreate student.find_special_workplan
    @special_work_plan = @student.find_special_workplan
    @work_plan_domain = @special_work_plan.work_plan_domains.includes(:work_plan_skills).find_or_create_by(work_plan: @special_work_plan, domain: domain, level: skills.first.level)

    WorkPlanDomain.add_wps_completed(skills, @work_plan_domain, @special_work_plan)

    redirect_to student_path(@student)
  end

  def remove_special_wps
    @wps = WorkPlanSkill.find(params[:work_plan_skill_id])
    authorize @wps
    @skill = @wps.skill
    @student = @wps.student
    # test if special domain
    unless @skill.specials?
      # exist il une belt pour lestudent le skill
      belt = Belt.where(domain: @skill.domain, student: @student, level: @skill.level, grade: @skill.grade)
      # belt to be destroy?
      belt.first.destroy unless belt.empty?
    end
    @wps.destroy
    render partial: "remove_special_wps"
  end

  private

  # PARAMS METHOD

  def set_params_wpskill_challenge
    params.require(:work_plan_skill).permit(:challenge_id)[:challenge_id]
  end

  def get_add_validated_wps_skill_student
    {
      student_id: params.permit(:student_id)[:student_id],
      skill_ids: params.require(:new_wps).permit(skills: [])[:skills][1..-1],
    }
  end

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

  # cONTROLLER PRIVATE METHOD
  def get_all_skills_to_add_completed_wps
    skills = []
    data = get_add_validated_wps_skill_student
    data[:skill_ids].delete("")
    data[:skill_ids].map { |skill_id|
      skills << Skill.for_school(current_user.school).find(skill_id)
    }
    {
      skills: skills,
      student: Student.includes(:classroom).find(data[:student_id]),
    }
  end
end
