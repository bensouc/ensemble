class Domain < ApplicationRecord
  belongs_to :grade
  acts_as_list scope: :grade
  has_many :skills, dependent: :destroy
  has_many :belts, dependent: :destroy
  has_many :work_plan_domains, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { message: "Le nom de cet domain éxiste déja", scope: :grade }
  # METHODS
  def special?
    special == true
  end
end
