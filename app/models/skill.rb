# frozen_string_literal: true

class Skill < ApplicationRecord
  has_many :work_plan_skills, dependent: nil
  has_many :challenges, dependent: :destroy

  validates :domain, presence: true,
                     inclusion: { in: ["Vocabulaire", "Conjugaison", "Orthographe",
                                      "Grammaire", "Numération", "Calcul", "Poésie", "Géométrie",
                                      "Grandeurs et Mesures"] }
  validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }
  validates :name, presence: true
  validates :symbol, presence: true
  validates :grade, presence: true

  def resolve_skill_id(domain, level, grade)
    Skill.where(domain: domain, level: level, grade: grade)
    # return a skill object
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
    end
  end
end
