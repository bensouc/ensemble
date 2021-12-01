class WorkPlan < ApplicationRecord
  belongs_to :user
  belongs_to :student, optional: true

  has_many :work_plan_domains
  accepts_nested_attributes_for :work_plan_domains
  
  has_many :work_plan_skills, through: :work_plan_domains

  validates :name, presence: true

end
