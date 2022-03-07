class WorkPlanSkill < ApplicationRecord
  belongs_to :work_plan_domain
  belongs_to :skill
  belongs_to :challenge, optional: true

  validates :kind, presence: true, inclusion: { in: %w(jeu exercice controle ceinture)}
end
