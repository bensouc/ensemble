# frozen_string_literal: true

class Student < ApplicationRecord
  belongs_to :classroom

  has_many :work_plans, dependent: :destroy
  accepts_nested_attributes_for :work_plans
  has_many :work_plan_domains, through: :work_plans
  has_many :work_plan_skills, through: :work_plan_domains

  # has_many :work_plan_skills, dependent: :destroy

  # has_many :work_plan_domains, dependent: :destroy

  has_many :belts, dependent: :destroy

  validates :first_name, presence: true

  def all_domains_from_student
    WorkPlanDomain::DOMAINS[classroom.grade]
  end

  def all_completed_work_plan_skills(domain, grade)
    work_plan_skills.includes([:skill]).select { |wps| wps.completed && wps.skill.grade == grade && wps.skill.domain == domain }
  end
end
