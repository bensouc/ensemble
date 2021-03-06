# frozen_string_literal: true

class WorkPlan < ApplicationRecord
  belongs_to :user
  belongs_to :student, optional: true

  has_many :work_plan_domains, dependent: :destroy
  accepts_nested_attributes_for :work_plan_domains

  has_many :work_plan_skills, through: :work_plan_domains
  accepts_nested_attributes_for :work_plan_skills

  validates :name, presence: true
  validates :grade, presence: true

  def all_domains_from_work_plan
    WorkPlanDomain::DOMAINS.select { |d| d[:grade] == grade }.first[:domains]
  end
end
