# frozen_string_literal: true

class Challenge < ApplicationRecord
  belongs_to :skill
  belongs_to :user
  has_rich_text :content
  has_many_attached :photos, dependent: :destroy

  has_many :work_plan_skills, dependent: nil

  validates :name, presence: true, uniqueness: { message: "Le nom de cet exercice éxiste déja", scope: :skill }
  validates :shared, presence: true

  def self.new_clone(challenge_original)
    Challenge.new(
      {
        name: "#{challenge_original.name}-Clone#{rand(1..10)}",
        content: challenge_original.content,
        skill_id: challenge_original.skill_id
      }
    )
  end

  def self.assigned_challenges(skill, student)
    wpss = WorkPlanSkill.where(student: student, skill_id: skill.id, kind: "exercice")
    # challenge = []
    wpss.map {|wps| wps.challenge}
  end

  def self.create_empty(work_plan_skill, name,current_user)
    challenge = Challenge.create({
                                   skill: work_plan_skill.skill,
                                   name: "#{name}-NEW",
                                   user: current_user
                                 })
    challenge.content.body = <<~HTML
      Exercice à REDIGER............................
    HTML
    challenge.save!
    challenge
  end
end
