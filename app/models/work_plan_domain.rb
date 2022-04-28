class WorkPlanDomain < ApplicationRecord
  DOMAINS = ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"]
  # order in the DOMAINS array give the Workplan show domain display ordering
  LEVELS = 1..7

  belongs_to :work_plan
  belongs_to :student, optional: true

  has_many :work_plan_skills, dependent: :destroy
  accepts_nested_attributes_for :work_plan_skills

  validates :domain, presence: true, inclusion: { in: DOMAINS }
  validates :level, presence: true, inclusion: { in: LEVELS }
  # validates :domain, presence: true, inclusion: { in: %w(Vocabulaire Grammaire Numération Calcul)}
  # validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }

  def all_domain_skills
    Skill.where(domain: self.domain, level: self.level, grade: self.work_plan.grade)
  end

  # test if a all skills are validated on a domain and
  # update completed status
  def all_skills_completed?
    # get all skills for a domain
    student = self.work_plan.student
    self.completed = self.all_domain_skills.all? do |skill|
      # test if wps is completed
      WorkPlanSkill.last_wps(student, skill).completed
    end
    self.save
    return self.completed
  end
end
