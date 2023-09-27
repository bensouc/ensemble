# frozen_string_literal: true

class Challenge < ApplicationRecord
  belongs_to :skill
  belongs_to :user
  has_rich_text :content
  has_many_attached :photos, dependent: :destroy
  has_one :school, through: :skill

  has_many :work_plan_skills, dependent: nil

  validates :name, presence: true, uniqueness: { message: "'Le nom de cet exercice éxiste déja'", scope: :skill }
  validates :shared, presence: true

  scope :for_belt, -> { where(for_belt: true) }
  scope :classic, -> { where(for_belt: false) }

  def for_belt?
    for_belt == true
  end

  def new_clone
    #  get sgid clone the attachement if table and attache it content
    content = self.content
    if self.content.body.to_s.include?("application/octet-stream")
      # content.body.to_s.gsub('"', "'").gsub(/sgid=\W(.*?)\W\scontent-type=\W+application/, "sgid='#{clone_table.attachable_sgid}' content-type='application")
      content = self.content.body.to_s.gsub('"', "'").gsub(/sgid=\W(.*?)\W\scontent-type=\W+application/) do |match|
        clone_table_challenge_from_sgid(match)
      end
    end
    Challenge.new(
      {
        name: "#{name}-Clone#{rand(1..100)}",
        content:,
        skill_id:,
      }
    )
  end

  def self.assigned_challenges(skill, student)
    wpss = WorkPlanSkill.where(skill_id: skill.id, kind: "exercice").select { |wps| wps.student == student }
    # challenge = []
    wpss.map(&:challenge)
  end

  def self.create_empty(work_plan_skill, name, current_user)
    challenge = Challenge.create({
                                   skill: work_plan_skill.skill,
                                   name: "#{name}-NEW",
                                   user: current_user,
                                 })
    challenge.content.body = <<~HTML
      Exercice à REDIGER............................
    HTML
    challenge.save
    challenge
  end

  private

  def clone_table_challenge_from_sgid(match)
    original_table = ActionText::Attachable.from_attachable_sgid(match.match(/sgid=\W(.*?)\W\scontent-type=\W+application/)[1])
    clone_table = original_table.clone
    # raise
    "sgid='#{clone_table.attachable_sgid}' content-type='application"
  end
end
