class Domain < ApplicationRecord
  belongs_to :grade
  has_many :skills
  has_many :work_plan_domains

  validates :name, presence: true,
                   uniqueness: { message: "Le nom de cet domain éxiste déja", scope: :grade }
  # METHODS
  def special?
    special == true
  end
end
