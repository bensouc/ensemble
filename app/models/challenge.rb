class Challenge < ApplicationRecord
  belongs_to :skill
  belongs_to :user
  has_rich_text :content

  has_many :work_plan_skills

  validates :name, presence: true, uniqueness: true
  validates :shared, presence: true
end
