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

  def grade
    classroom.grade
  end

  def all_domains_from_student
    WorkPlanDomain::DOMAINS[classroom.grade]
  end

  def all_completed_work_plan_skills(domain, grade)
    work_plan_skills.includes([:skill]).select { |wps| wps.completed && wps.skill.grade == grade && wps.skill.domain == domain }
  end

  def all_completed_challenge_work_plan_skills(domain, grade)
    work_plan_skills.includes([:skill]).select { |wps| wps.completed && wps.skill.grade == grade && wps.skill.domain == domain && wps.kind="exercice" }
  end

  def find_special_workplan

    WorkPlan.includes(:work_plan_domains).where(student: self, grade: , name:'special_work_plan', special_wps: true).find_or_create_by!(student: self, grade: ,user: classroom.user, name:'special_work_plan', special_wps: true)
  end
end
