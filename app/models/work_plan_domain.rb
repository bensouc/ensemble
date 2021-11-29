class WorkPlanDomain < ApplicationRecord
  belongs_to :work_plan

  has_many :work_plan_skills

  validates :domain, presence: true
  validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }
end
