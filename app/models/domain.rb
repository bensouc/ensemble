class Domain < ApplicationRecord
  belongs_to :grade
  acts_as_list scope: :grade
  has_many :skills, dependent: :destroy
  has_many :belts, dependent: :destroy
  has_many :work_plan_domains, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { message: "Le nom de cet domain éxiste déja", scope: :grade }

  # METHODS
  delegate :grade_level, to: :grade

  def special?
    special == true
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
