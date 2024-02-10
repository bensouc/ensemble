class Domain < ApplicationRecord
  belongs_to :grade
  has_many :skills

  validates :name, presence: true,
                   uniqueness: { message: "Le nom de cet domain éxiste déja", scope: :grade }
end
