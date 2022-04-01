class Student < ApplicationRecord
  belongs_to :classroom

  has_many :work_plans
  accepts_nested_attributes_for :work_plans

  has_many :work_plan_skills
  accepts_nested_attributes_for :work_plans

  validates :first_name, presence: true
end
