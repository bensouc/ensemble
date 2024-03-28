class SchoolRole < ApplicationRecord
  belongs_to :user
  belongs_to :school

  validates :school, uniqueness: { scope: :user, message: "Vous avez déjà un roel dans ce Groupe/ Ecole" }

  def super_teacher?
    super_teacher
  end
end
