# frozen_string_literal: true

class WorkPlan < ApplicationRecord
  belongs_to :user
  belongs_to :grade #to remove for first migration Of Grade MODEL
  belongs_to :shared_user, class_name: "User", optional: true
  belongs_to :student, optional: true

  has_many :work_plan_domains, dependent: :destroy
  accepts_nested_attributes_for :work_plan_domains

  has_many :work_plan_skills, through: :work_plan_domains
  accepts_nested_attributes_for :work_plan_skills
  has_many :challenges, through: :work_plan_skills
  has_many :skills, through: :work_plan_skills

  validates :name, presence: true

  def all_domains_from_work_plan
    WorkPlanDomain::DOMAINS[grade.grade_level]
  end

  def special_wps?
    special_wps == true
  end

  def self.with_associations
    includes( [:skills, :challenges] )
  end
end
