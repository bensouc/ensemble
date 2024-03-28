# frozen_string_literal: true

class Skill < ApplicationRecord
  belongs_to :school
  belongs_to :domain
  has_many :work_plan_skills, dependent: nil
  has_many :challenges, dependent: :destroy

  validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }
  validates :name, presence: true
  #  uniqueness: { message: "Le nom de compétence éxiste déja", scope: :domain }
  validates :domain, presence: true
  validates :symbol, inclusion: { in: ["◼", "⬥", "⬟", "♥", "⬤", "♣", "🞮", "▲", ""] }

  # Class methods
  def self.for_school(school)
    where(school:)
  end


  def self.sheets_to_temp_skills_creation(xlsx_sheets , grade, user,domains)
    errors = { domains: [], skills: [] }
    skills = []
    xlsx_sheets.each do |domain_sheet|
      if domains.any?{|domain| domain.name == domain_sheet.name}
        # pour chauqe rows [1..-1] new skills is made # #<Skill id: nil, domain: nil, level: nil, name: nil, symbol: nil,#  nil, sub_domain: nil, school_id: nil, grade_id: nil>
        domain_sheet.rows[1..-1].each do |row| # row =>["Ceinture", "Symbole", "Compétences"]
          if !(row.first.nil? || row.last.nil? || row.last.empty?)
            skills << Skill.new(domain: domains.find{|domain| domain.name == domain_sheet.name}, level: Belt::BELT_COLORS.index(row.first) + 1,
              name: row.last, symbol: row.second, school: user.school)
          else
            errors[:skills] << "La ligne #{row} doit avoir une couleur de ceinture et nom de compétence"
          end
        end
      else
        puts "Le domaine #{domain_sheet.name} n'existe pas pour #{grade.name}"
        errors[:domains] << "Le domaine #{domain_sheet.name} n'existe pas pour #{grade.name}"
      end
    end
    # renvoie des erreur ou un lot de skills
    { errors:, skills: }
  end

  def self.create_loaded_skills(temp_skills)
    temp_skills.each {|skill| skill.save}
  end

# Instances method

  # ###########################################
  # METHODS
  delegate :grade, to: :domain

  def resolve_skill_id(domain, level, grade)
    Skill.for_school(current_user.school).where(domain:, level:, grade:)
    # return a skill object
  end

  delegate :special?, to: :domain

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
