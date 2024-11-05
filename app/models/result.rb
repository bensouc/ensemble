class Result < ApplicationRecord
  belongs_to :student
  belongs_to :skill
  validates :student, uniqueness: { scope: :skill, message: "Il y déjà un résultat pour cette compétnce et pour cet élève" }
  scope :completed, -> { where(status: "completed", kind: "ceinture") }
  scope :completed_for_student, ->(student) { where(student:, status: "completed") }

  def belt_validated?
    kind == "ceinture" && status == "completed"
  end

  def challenge_validated?
    kind == "exercice" && status == "completed"
  end

  def self.update_with_new_belt(belt)
    # get all skills from belt domain
    skills = belt.domain.skills.select { |skill| skill.level == belt.level }
    # find or creates special_wps and pass it as validated and ceinture
    skills.each do |skill|
      Result.find_or_create_by(student: belt.student, skill: skill).update!(status: "completed", kind: "ceinture")
    end
  end
end
