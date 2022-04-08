class WorkPlanSkill < ApplicationRecord
  belongs_to :work_plan_domain
  belongs_to :skill
  belongs_to :challenge, optional: true
  belongs_to :student, optional: true

  validates :kind, presence: true, inclusion: { in: %w(jeu exercice controle ceinture)}
  validates :status, inclusion: {in: %w(redo failed redo_OK completed new)}

end
