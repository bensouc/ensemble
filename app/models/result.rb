class Result < ApplicationRecord
  belongs_to :student
  belongs_to :skill
  validates :student, uniqueness: { scope: :skill, message: "Il y déjà un résultat pour cette compétnce et pour cet élève" }
end
