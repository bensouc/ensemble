# frozen_string_literal: true

class Skill < ApplicationRecord
  has_many :work_plan_skills, dependent: nil
  has_many :challenges, dependent: :destroy

  validates :domain, presence: true,
                     inclusion: { in: ["Vocabulaire", "Conjugaison", "Orthographe",
                                      "Grammaire", "Numération", "Calcul", "Géométrie",
                                      "Grandeurs et Mesures"] }
  validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }
  validates :name, presence: true
  validates :symbol, presence: true
  validates :grade, presence: true

  def resolve_skill_id(domain, level, grade)
    Skill.where(domain: domain, level: level, grade: grade)
    # return a skill object
  end

  def symbol_pdf
    case symbol
    when "◼"
      "square_tu53ju.png"
    when "⬥"
      "losange_w2zsyz.png"
    when "⬟"
      "polyhedre_orzmw2.png"
    when "♥"
      "heart_e87l5c.png"
    when "⬤"
      "circle_u6lb1y"
    when "♣"
      "spades_hgpeze.png"
    when "🞮"
      "croix_fddn5r.png"
    when "▲"
      "triangle_ahjvqq.png"
    end
  end
end
