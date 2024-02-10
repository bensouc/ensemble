# frozen_string_literal: true

class WorkPlanDomain < ApplicationRecord
  DOMAINS = {
    # order in the DOMAINS array give the Workplan show domain display ordering
    "CP" => ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"],
    "CE1" => ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"],
    "CE2" => ["Conjugaison", "Vocabulaire", "Grammaire", "Numération", "Calcul",
              "Géométrie", "Grandeurs et Mesures"],
    "CM1" => ["Conjugaison", "Vocabulaire", "Orthographe", "Grammaire", "Poésie", "Géométrie", "Grandeurs et Mesures",
              "Numération", "Calcul"],
    "CM2" => ["Calcul", "Géométrie", "Grandeurs et Mesures", "Numération", "Opérations",
              "Résolution des Problèmes", "Calligraphie", "Conjugaison",
              "Poésie et Expression orale", "Production d’écrit", "Grammaire",
              "Lecture", "Vocabulaire"]
  }.freeze
  LEVELS = (1..7)

  DOMAINS_SPECIALS = ["Géométrie", "Grandeurs et Mesures"].freeze

  # ASSOCIATIONS
  belongs_to :work_plan
  # belongs_to :student, optional: true
  belongs_to :domain
  has_one :student, through: :work_plan

  # VALIDATIONS
  has_many :work_plan_skills, dependent: :destroy
  accepts_nested_attributes_for :work_plan_skills
  validates :level, presence: true, inclusion: { in: LEVELS }

  # def student
  #   return work_plan.student if association(:work_plan).loaded?

  #   super
  # end
  # METHODS
  def specials?
    # binding.pry
    work_plan.grade.school.special_domains? && domain.in?(DOMAINS_SPECIALS) && work_plan.grade.grade_level != "CM2"
  end

  def all_domain_skills(user)
    Skill.for_school(user.school).where(domain:, level:, grade: work_plan.grade)
  end

  def name
    domain.name
  end
  def self.add_wps_completed(skills, work_plan_domain, special_work_plan)
    last_work_plan_skill = nil
    skills.each do |skill|
      work_plan_skill = WorkPlanSkill.create!(
        work_plan_domain:,
        skill:,
        status: "completed",
        completed: true,
        kind: "ceinture"
      )
      last_work_plan_skill = work_plan_skill
      # validate BElt?
      # raise
      if WorkPlanDomain::DOMAINS_SPECIALS.include?(work_plan_domain.domain) && skill.grade.grade_level != "CM2"
        Belt.special_newbelt(work_plan_skill, special_work_plan)
        last_work_plan_skill = nil
        # BMO TO be rethinkg to get result from method
      elsif work_plan_domain.all_skills_completed?
        belt = Belt.find_or_create_by(
          { student_id: special_work_plan.student.id,
            domain: work_plan_domain.domain,
            grade: skill.grade,
            level: skill.level }
        )
        belt.completed = true
        belt.validated_date = DateTime.now
        belt.save
      end
    end
    last_work_plan_skill
  end

  # test if a all skills are validated on a domain and
  # update completed status
  def all_skills_completed?
    # get all skills for a domain
    # temp_all_domain_skill = all_domain_skills
    student = work_plan.student
    self.completed = all_domain_skills(work_plan.user).all? do |skill|
      # test if wps is completed
      temp_wps = WorkPlanSkill.last_wps(student, skill).select do |wps|
        wps.skill == skill && wps.kind == "ceinture"
      end.max_by(&:created_at)
      temp_wps.completed unless temp_wps.nil?
    end
    save
    completed
  end

  # return the number of validated skill for a domain
  def all_skills_completed_count
    student = work_plan.student
    out = all_domain_skills(work_plan.user).select do |skill|
      temp_last_wpss = WorkPlanSkill.last_wps(student, skill)[-1]
      !temp_last_wpss.nil? && temp_last_wpss.completed
    end
    out.count
  end
end
