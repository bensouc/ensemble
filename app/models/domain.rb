class Domain < ApplicationRecord
  # `optional` : la colonne accepte NULL en base. À resserrer (NOT NULL, puis
  # `optional` retiré) une fois les lignes vides comptées en production.
  belongs_to :grade, optional: true
  acts_as_list scope: :grade
  include Positionable

  has_many :skills, dependent: :destroy
  has_many :belts, dependent: :destroy
  has_many :work_plan_domains, dependent: :destroy
  has_many :auto_gen_exclusions, dependent: :delete_all

  validates :name, presence: true,
                   uniqueness: { message: "est déjà utilisé pour ce niveau", scope: :grade }

  # METHODS
  delegate :grade_level, to: :grade

  def special?
    special == true
  end

  # Le bloc plutôt qu'une requête : l'association se charge une fois, et la page
  # des domaines pose la question pour chacun d'eux.
  def auto_gen_for?(user)
    user.auto_gen_exclusions.none? { |exclusion| exclusion.domain_id == id }
  end

  def all_skills_completed(student, level)
    skills_at_level = skills.select { |skill| skill.level == level }
    results = Result.completed.where(student:, skill: skills_at_level)
    skills_at_level.select do |skill|
      results.detect { |result| result.skill == skill && result.belt_validated? }
    end
  end

  def all_skills_completed?(student, level)
    # get all skills for a domain
    # temp_all_domain_skill = all_domain_skills
    skills_at_level = skills.select { |skill| skill.level == level }
    results = Result.completed.where(student:, skill: skills_at_level)
    skills_at_level.all? do |skill|
      results.find { |result| result.skill == skill && result.belt_validated? }
    end
  end
end
