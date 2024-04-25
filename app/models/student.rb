 # frozen_string_literal: true

class Student < ApplicationRecord
  belongs_to :classroom

  has_many :work_plans, dependent: :destroy
  accepts_nested_attributes_for :work_plans
  has_many :work_plan_domains, through: :work_plans
  has_many :work_plan_skills, through: :work_plan_domains
  has_many :belts, dependent: :destroy
  has_many :results, dependent: :destroy

  validates :first_name, presence: true

  delegate :grade, to: :classroom

  def all_domains_from_student
    grade.domains
  end

  def belt_status(domain, level)
    Belt.completed.where(student: self, domain:, level:).count.positive?
  end

  def skill_status(skill, _kind = nil)
    # get all wps for this student and this skill
    # binding.pry
    # target_work_plan_skills = kind.nil? ? work_plan_skills.where(skill:) : work_plan_skills.where(skill:, kind:)
    target_work_plan_skills = work_plan_skills.where(skill:)

    # if nil? => return 'skill_status_challenge'
    # if target_work_plan_skills.nil?
    #   'skill_status_challenge'
    #   # if one of them has a wps.completed = true => out=> 'skill_status_completed'
    # els
    if target_work_plan_skills.any?(&:completed)
      "skill_status_completed"
      # if one of them has wps.status == "completed" && wps.kind == "exercice"
    elsif target_work_plan_skills.any? do |work_plan_skill|
            work_plan_skill.status == "completed" && work_plan_skill.kind == "exercice"
          end
      # out=>"skill_status_belt"
      "skill_status_belt"
      # else => return status:skill_status_challenge
    else
      "skill_status_challenge"
    end
  end

  def all_completed_work_plan_skills(domain)
    work_plan_skills.includes([:skill]).select { |wps| wps.completed && wps.skill.domain == domain }
  end

  def all_completed_challenge_work_plan_skills(domain, grade)
    work_plan_skills.includes([:skill]).select do |wps|
      wps.completed && wps.skill.grade.grade_level == grade && wps.skill.domain == domain && wps.kind = "exercice"
    end
  end

  def find_special_workplan
    WorkPlan.includes(:work_plan_domains).where(student: self, grade:, name: "special_work_plan", special_wps: true).find_or_create_by!(
      student: self, grade:, user: classroom.user, name: "special_work_plan", special_wps: true
    )
  end

  def derniers_work_planskills_etudiant
    # On récupère tous les work_plan_skills de l'étudiant
    work_planskills_etudiant = work_plan_skills.includes(:skill).order(updated_at: :desc)
    # On crée un hash pour stocker les derniers work_plan_skills pour chaque compétence
    derniers_work_planskills = {}
    # On parcourt les work_plan_skills de l'étudiant
    work_planskills_etudiant.each do |work_planskill|
      # On récupère l'ID de la compétence
      skill = work_planskill.skill

      # On vérifie si un work_plan_skill pour cette compétence a déjà été ajouté au hash
      # Si c'est le cas, on vérifie si le work_plan_skill actuel est plus récent que celui stocké
      unless derniers_work_planskills[skill].nil? || work_planskill.updated_at > derniers_work_planskills[skill].updated_at
        next
      end

      derniers_work_planskills[skill] = work_planskill
    end
    # On retourne le hash contenant les derniers work_plan_skills pour chaque compétence
    derniers_work_planskills # {skill => last_work_plan_skill, skill => last_work_plan_skill}
  end
end
