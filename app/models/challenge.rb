class Challenge < ApplicationRecord
  belongs_to :skill
  belongs_to :user
  has_rich_text :content
  has_many_attached :photos

  has_many :work_plan_skills

  validates :name, presence: true, uniqueness: { message: 'Le nom de cet éxercice éxiste déja' }
  validates :shared, presence: true
end
