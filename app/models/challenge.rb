class Challenge < ApplicationRecord
  belongs_to :skill
  belongs_to :user
  has_rich_text :content
  has_many_attached :photos

  has_many :work_plan_skills

  validates :name, presence: true, uniqueness: { message: "Le nom de cet exercice éxiste déja" }
  validates :shared, presence: true

  def self.new_clone(challenge_original)
    return Challenge.new(
             {
               name: "#{challenge_original.name}-Clone#{rand(1..10)}",
               content: challenge_original.content,
               skill_id: challenge_original.skill_id,
             }
           )
  end

  def self.create_empty(work_plan_skill, name, user)
    challenge = Challenge.create({
      skill: work_plan_skill.skill,
      name: "#{name}-NEW",
      user: user
    })
    challenge.content.body = <<~HTML
      Exercice à REDIGER............................
    HTML
    challenge.save!
    return challenge
  end
end
