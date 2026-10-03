class SchoolRole < ApplicationRecord
  # `optional` : les colonnes acceptent NULL en base. À resserrer (NOT NULL, puis
  # `optional` retiré) une fois les lignes vides comptées en production.
  belongs_to :user, optional: true
  belongs_to :school, optional: true

  validates :school, uniqueness: { scope: :user, message: "Vous avez déjà un roel dans ce Groupe/ Ecole" }

  def super_teacher?
    super_teacher
  end
end
