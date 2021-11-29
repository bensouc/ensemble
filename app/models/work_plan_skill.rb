class WorkPlanSkill < ApplicationRecord
  belongs_to :work_plan_domain
  belongs_to :skill
  belongs_to :challenge

  belongs_to :work_plan, through: :work_plan_domain

  validates :kind, presence: true, inclusion: { in: %w(jeu excercice controle)}
end
