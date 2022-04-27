class Skill < ApplicationRecord
  has_many :work_plan_skills
  has_many :challenges

  validates :domain, presence: true, inclusion: { in: ['Vocabulaire', 'Grammaire', 'Numération', 'Calcul', 'Géométrie', 'Grandeurs et Mesures'] }
  validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }
  validates :name, presence: true
  validates :symbol, presence: true
  validates :grade, presence: true

  def resolve_skill_id(domain, level, grade)
    Skill.where(domain: domain, level: level, grade: grade)
    # return a skill object
  end
end
