class Result < ApplicationRecord
  belongs_to :student
  belongs_to :skill
  validates :student, uniqueness: { scope: :skill, message: "Il y déjà un résultat pour cette compétnce et pour cet élève" }
  scope :completed, -> { where(status: "completed", kind: "ceinture") }
  def belt_validated?
    kind == "ceinture" && status == "completed"
  end

  def challenge_validated?
    kind == "exercice" && status == "completed"
  end
end
