# frozen_string_literal: true

class Student < ApplicationRecord
  belongs_to :classroom

  has_many :work_plans, dependent: :destroy
  accepts_nested_attributes_for :work_plans

  has_many :work_plan_skills, dependent: :destroy
  accepts_nested_attributes_for :work_plans

  has_many :work_plan_domains, dependent: :destroy

  has_many :belts, dependent: :destroy

  validates :first_name, presence: true

  def all_domains_from_student
    WorkPlanDomain::DOMAINS.select { |d| d[:grade] == classroom.grade }.first[:domains]
  end

  
end
