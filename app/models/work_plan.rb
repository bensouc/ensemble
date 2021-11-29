class WorkPlan < ApplicationRecord
  belongs_to :user
  belongs_to :student

  has_many :work_plan_domains
  has_many :work_plan_skills, through: :work_plan_domains

  validates :name, presence: true
end
