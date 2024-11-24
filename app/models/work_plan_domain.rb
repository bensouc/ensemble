# frozen_string_literal: true

class WorkPlanDomain < ApplicationRecord
  DOMAINS = {
    # order in the DOMAINS array give the Workplan show domain display ordering
    "CP" => ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"],
    "CE1" => ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"],
    "CE2" => ["Conjugaison", "Vocabulaire", "Grammaire", "Numération", "Calcul",
              "Géométrie", "Grandeurs et Mesures"],
    "CM1" => ["Conjugaison", "Vocabulaire", "Orthographe", "Grammaire", "Poésie", "Géométrie", "Grandeurs et Mesures",
              "Numération", "Calcul"],
    "CM2" => ["Calcul", "Géométrie", "Grandeurs et Mesures", "Numération", "Opérations",
              "Résolution des Problèmes", "Calligraphie", "Conjugaison",
              "Poésie et Expression orale", "Production d’écrit", "Grammaire",
              "Lecture", "Vocabulaire"],
  }.freeze
  LEVELS = (1..7)

  DOMAINS_SPECIALS = ["Géométrie", "Grandeurs et Mesures"].freeze

  # ASSOCIATIONS
  belongs_to :work_plan
  # belongs_to :student, optional: true
  belongs_to :domain
  has_one :student, through: :work_plan

  # VALIDATIONS
  has_many :work_plan_skills, dependent: :destroy
  accepts_nested_attributes_for :work_plan_skills
  validates :level, presence: true, inclusion: { in: LEVELS }

  # def student
  #   return work_plan.student if association(:work_plan).loaded?

  #   super
  # end
  # METHODS
  def special?
    # binding.pry
    domain.special?
  end

  def all_domain_skills(user)
    Skill.where(domain:, level:, school: user.school)
  end

  def attach_next_skills(current_user, results)
    Skill.where(domain:, level: level).sort_by(&:position).each do |skill|
      # result = Result.find_by(skill:, student:)
      result = results.to_a.find { |result| result.skill == skill }
      # raise if skill.id == 105
      next if (!result.nil? && result.belt_validated?) || (result.nil? && special?) # rubocop:disable Style/IfUnlessModifier
      kind =  if result.nil? || result.kind.nil?
                "exercice"
              else
                result.challenge_validated? ? "ceinture" : result.kind
              end
      new_wps = WorkPlanSkill.new(
        skill:,
        work_plan_domain: self,
        kind: kind,
        status: "new"
      )

      new_wps.attach_content(result, current_user)
    end
  end

end
