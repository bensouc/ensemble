# frozen_string_literal: true

class WorkPlanDomain < ApplicationRecord
  DOMAINS = [
    # order in the DOMAINS array give the Workplan show domain display ordering
    {
      grade: "CE1",
      domains: ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"]
    },
    {
      grade: "CE2",
      domains: ["Conjugaison", "Vocabulaire", "Orthographe", "Grammaire", "Géométrie", "Grandeurs et Mesures",
                "Numération", "Calcul"]
    },
    {
      grade: "CM1",
      domains: ["Conjugaison", "Vocabulaire", "Orthographe", "Grammaire", "Poesie", "Géométrie", "Grandeurs et Mesures",
                "Numération", "Calcul"]
    }
  ].freeze
  LEVELS = (1..7).freeze

  DOMAINS_SPECIALS = ["Géométrie", "Grandeurs et Mesures"].freeze

  belongs_to :work_plan
  belongs_to :student, optional: true

  has_many :work_plan_skills, dependent: :destroy
  accepts_nested_attributes_for :work_plan_skills

  # validates :domain, presence: true, inclusion: { in: DOMAINS } => can not be other
  validates :level, presence: true, inclusion: { in: LEVELS }
  # validates :domain, presence: true, inclusion: { in: %w(Vocabulaire Grammaire Numération Calcul)}
  # validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }

  def all_domain_skills
    Skill.where(domain: domain, level: level, grade: work_plan.grade)
  end

  # test if a all skills are validated on a domain and
  # update completed status
  def all_skills_completed?
    # get all skills for a domain
    student = work_plan.student
    self.completed = all_domain_skills.all? do |skill|
      # test if wps is completed
      WorkPlanSkill.last_wps(student, skill).completed
    end
    save
    completed
  end

  # return the number of validated skill for a domain
  def all_skills_completed_count
    student = work_plan.student
    out = all_domain_skills.select do |skill|
      !WorkPlanSkill.last_wps(student, skill).nil? && WorkPlanSkill.last_wps(student, skill).completed
    end
    out.count
  end
end
