class Skill < ApplicationRecord
  has_many :work_plan_skills
  has_many :challenges

  validates :domain, presence: true
  validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }
  validates :name, presence: true
  validates :symbol, presence: true

end
