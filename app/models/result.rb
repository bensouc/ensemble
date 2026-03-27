class Result < ApplicationRecord
  belongs_to :student
  belongs_to :skill
  validates :student,
            uniqueness: { scope: :skill, message: "Il y déjà un résultat pour cette compétnce et pour cet élève" }
  scope :completed, -> { where(status: "completed", kind: "ceinture") }
  scope :completed_for_student, -> (student) { includes([:skill]).where(student:, status: "completed") }
  scope :belts, -> { where(kind: "ceinture") }

  after_commit :belt_update_by_domain_and_level, on: [:create, :update]

  def belt_validated?
    kind == "ceinture" && status == "completed"
  end

  def challenge_validated?
    kind == "exercice" && status == "completed"
  end

  def validate!
    update!(kind: "ceinture", status: "completed")
  end

  def completed?
    status == "completed"
  end

  def self.update_with_new_belt(belt)
    skills = belt.domain.skills.select { |skill| skill.level == belt.level }
    skills.each do |skill|
      result = Result.find_or_create_by(student: belt.student, skill: skill)
      result.update_columns(status: "completed", kind: "ceinture") unless result.belt_validated?
    end
  end

  def belt_update_by_domain_and_level
    domain = skill.domain
    level = skill.level
    belt = Belt.find_by(student:, domain:, level:)
    belt = Belt.create!(student:, domain:, level:) if belt.nil?
    skills = Skill.for_school(student.school).where(domain:, level:)
    results = Result.where(student:, skill: skills)

    if domain.special?
      # binding.pry
      Belt.update_special_belts_on_domain(domain, student)
    elsif results.all? { |r| r.belt_validated? } && results.count == skills.count
      belt.complete!
    else
      belt.uncomplete!
    end
  end
end
