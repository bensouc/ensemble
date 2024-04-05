# frozen_string_literal: true

class WorkPlanSkill < ApplicationRecord
  after_validation :update_result, only: %w[create update]
  after_destroy :reset_result

  belongs_to :work_plan_domain
  belongs_to :skill
  belongs_to :challenge, optional: true
  # belongs_to :student, optional: true
  has_one :student, through: :work_plan_domain

  validates :kind, presence: true, inclusion: { in: %w[jeu exercice controle ceinture] }
  validates :status, inclusion: { in: %w[redo failed redo_OK completed new] }

  # def student
  #   return super unless association(:work_plan_domain).loaded? &&
  #                       work_plan_domain.association(:work_plan).loaded?

  #   work_plan_domain.work_plan.student
  # end
  def completed?
    completed == true
  end

  def special_wps?
    work_plan_domain.work_plan.special_wps
  end

  def clone(_current_wp, new_wp_domain)
    new_wps = dup
    new_wps.work_plan_domain_id = new_wp_domain.id
    # new_wps.student = student
    new_wps.status = "new"
    new_wps.completed = false
    new_wps.save
  end

  def add_challenges_2_wps(current_user, _actual_challenge = nil)
    challenges = Challenge.classic.where(skill_id: skill)
    name = skill.name + " " + (challenges.count + 1).to_s
    # get all challenges azssigned 4 current_student and that skill
    student_challenges = Challenge.assigned_challenges(skill, student)
    # challenges = challenges.reject { |c| c == actual_challenge }
    challenges = challenges.reject { |c| student_challenges.include?(c) }

    # [1,2,3].reject{|c| c==4}
    if challenges.empty?
      # if no existing challeng 4 that skill
      # create a empty challenge 4 that skill
      Challenge.create_empty(self, name, current_user)
    else
      # recuper un des exo existant avec le skill id de @self
      challenges.sample
    end
  end

  def self.last_4_wps(_work_plan, wps, current_student)
    # retrieve the last 4 wps for the student on this skill ids
    out = WorkPlanSkill.includes([:student]).where(skill_id: wps.skill_id)
    out = out.select { |work_plan_skill| work_plan_skill.student == current_student }.sort_by(&:created_at).reverse
    out.reject { |t| t == wps }
    out.last(3)
  end

  # def self.last_wps_by_skills(student, skills)
  #   WorkPlanSkill.where(skill: skills, student: student)
  #                 .order(updated_at: :desc)
  #                 .first
  # end

  def self.last_wps(student, skills)
    # WorkPlanSkill.where(skill: skill).select{ |s| s.student == student }.max_by(&:created_at)

    wpss = WorkPlanSkill.includes([:skill, :work_plan_domain, :student]).where(skill: skills)
    wpss.select { |wps| wps.student == student }
  end

  private

  def update_result
    # find_or_create results
    result = Result.find_or_create_by(student:, skill:)
    # update results
    result.update!(status:, kind:)
  end

  def reset_result
    return unless special_wps?

    # find_or_create results
    result = Result.find_or_create_by(student:, skill:)
    # update results
    result.update!(status: "new", kind:)
  end
end
