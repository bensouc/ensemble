class WorkPlanDomain < ApplicationRecord
  DOMAINS = ['Vocabulaire', 'Grammaire', 'Numération', 'Calcul', 'Géométrie', 'Grandeurs et Mesures']
  LEVELS = 1..7

  belongs_to :work_plan

  has_many :work_plan_skills, dependent: :destroy
  accepts_nested_attributes_for :work_plan_skills

  validates :domain, presence: true, inclusion: { in: DOMAINS }
  validates :level, presence: true, inclusion: { in: LEVELS }
  # validates :domain, presence: true, inclusion: { in: %w(Vocabulaire Grammaire Numération Calcul)}
  # validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }
end
