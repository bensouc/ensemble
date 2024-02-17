# frozen_string_literal: true

class Skill < ApplicationRecord
  belongs_to :school
  belongs_to :domain
  has_many :work_plan_skills, dependent: nil
  has_many :challenges, dependent: :destroy

  validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }
  validates :name, presence: true
                  #  uniqueness: { message: "Le nom de compétence éxiste déja", scope: :domain }

  validates :symbol, inclusion: { in: ["◼", "⬥", "⬟", "♥", "⬤", "♣", "🞮", "▲", ""] }


  def self.for_school(school)
    where(school:)
  end
# ###########################################
  # METHODS
  def grade
    domain.grade
  end
  def resolve_skill_id(domain, level, grade)
    Skill.for_school(current_user.school).where(domain:, level:, grade:)
    # return a skill object
  end

  def special?
    domain.special?
  end

  def symbol_img_name
    case symbol
    when "◼"
      "square2_yhovlm.png"
    when "⬥"
      "losange2_zgouqt.png"
    when "⬟"
      "polyhedre2_r6ydug.png"
    when "♥"
      "heart2_u2phzr.png"
    when "⬤"
      "circle2_tvcz8s.png"
    when "♣"
      "spades2_kb8mjr.png"
    when "🞮"
      "croix2_cosycf.png"
    when "▲"
      "triangle2_ehwxbb.png"
    when ""
      "empty_rrq3rq.png"
    end
  end
end
