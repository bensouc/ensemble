# frozen_string_literal: true
# rubocop:disable all

class Belt < ApplicationRecord
  BELT_COLORS = %w[blanche jaune orange verte bleue marron noire].freeze
  BELT_PNG = {
    "1" => "https://res.cloudinary.com/bensoucdev/image/upload/v1666698313/ensemble/belts/belt_1_jkd7er.png",
    "2" => "https://res.cloudinary.com/bensoucdev/image/upload/v1666698313/ensemble/belts/belt_2_yuzuqg.png",
    "3" => "https://res.cloudinary.com/bensoucdev/image/upload/v1666712976/ensemble/belts/belt_3_yntgyk.png",
    "4" => "https://res.cloudinary.com/bensoucdev/image/upload/v1666698313/ensemble/belts/belt_4_s2d5du.png",
    "5" => "https://res.cloudinary.com/bensoucdev/image/upload/v1666698313/ensemble/belts/belt_5_lefmhr.png",
    "6" => "https://res.cloudinary.com/bensoucdev/image/upload/v1666698313/ensemble/belts/belt_6_mqzhbq.png",
    "7" => "https://res.cloudinary.com/bensoucdev/image/upload/v1666698314/ensemble/belts/belt_7_aubna5.png"
  }.freeze
  belongs_to :grade
  belongs_to :student
  scope :completed, -> { where(completed: true) }

  # validations
  # validates :student, presence: true
  # validates :level, presence: true
  validates :domain, presence: true, inclusion: { in: ["Vocabulaire", "Conjugaison", "Orthographe",
       "Grammaire", "Numération", "Calcul", "Poésie", "Géométrie",
       "Grandeurs et Mesures", "Opérations", "Résolution des Problèmes",
       "Calligraphie","Poésie", "Poésie et Expression orale",
       "Production d’écrit", "Lecture"] }
  # validates :grade, presence: true, inclusion: { in: %w[CP CE1 CE2 CM1 CM2] }
  validates :level, presence: true, inclusion: { in: [1, 2, 3, 4, 5, 6, 7] }
  validates :student, uniqueness: { scope: %i[domain grade level] }

  def completed?
    completed
  end

  def all_skills(user)
    Skill.for_school(user.school).where(level:, grade:, domain:)
  end


  def self.student_last_belt_level(student, domain)
    belt = Belt.where(student:, domain:, completed: true).order(level: :desc).first
    if belt.nil?
      1
    else
      belt.level + 1
    end
  end

  # Belt.special_newbelt(work_plan_skill, special_work_plan)
  def self.special_newbelt(work_plan_skill, work_plan)
    count = work_plan_skill.work_plan_domain.all_skills_completed_count
    args = {
      student_id: work_plan_skill.student.id,
      domain: work_plan_skill.work_plan_domain.domain,
      grade: work_plan.grade
    }
    Belt.create_new_special_belt(args, count, work_plan_skill)
    # raise
  end

  def self.find_or_create_by_level!(args, level)
    binding.pry
    (1..level).each do
      args.merge!(
        {
          level:
        }
      )
      belt = Belt.find_or_create_by(args)
      belt.completed = true
      belt.validated_date = DateTime.now
      belt.save
    end
  end

  SCORES_TO_VALIDATES =
    {
      "CE1" => [
        {
          domain: "Géométrie",
          validation: [2, 4, 7, 10, 13, 17, 21]
        },
        {
          domain: "Grandeurs et Mesures",
          validation: [2, 4, 6, 9, 12, 15, 18]
        }
      ],
      "CE2" => [
        {
          domain: "Géométrie",
          validation: [2, 4, 7, 10, 13, 17, 21]
        },
        {
          domain: "Grandeurs et Mesures",
          validation: [3, 7, 11, 15, 19, 23, 28]
        }
      ],
      "CM1" => [
        {
          domain: "Géométrie",
          validation: [2, 5, 8, 12, 16, 21, 26]
        },
        {
          domain: "Grandeurs et Mesures",
          validation: [3, 7, 11, 16, 21, 27, 33]
        }
      ]
    }.freeze

  def self.score_to_validate(grade)
    Belt::SCORES_TO_VALIDATES[grade]
  end

  def self.create_new_special_belt(args, count, work_plan_skill)
    case args[:grade]
    when "CE1"
      case work_plan_skill.work_plan_domain.domain
      when "Géométrie"
        case count
        when 2...4
          Belt.find_or_create_by_level!(args, 1)
        when 4...7
          Belt.find_or_create_by_level!(args, 2)
        when 7...10
          Belt.find_or_create_by_level!(args, 3)
        when 10...13
          Belt.find_or_create_by_level!(args, 4)
        when 13...17
          Belt.find_or_create_by_level!(args, 5)
        when 17...21
          Belt.find_or_create_by_level!(args, 6)
        when 21
          Belt.find_or_create_by_level!(args, 7)
        end
      when "Grandeurs et Mesures"
        case count
        when 2...4
          Belt.find_or_create_by_level!(args, 1)
        when 4...5
          Belt.find_or_create_by_level!(args, 2)
        when 5...9
          Belt.find_or_create_by_level!(args, 3)
        when 9...12
          Belt.find_or_create_by_level!(args, 4)
        when 12...15
          Belt.find_or_create_by_level!(args, 5)
        when 15...18
          Belt.find_or_create_by_level!(args, 6)
        when 18
          Belt.find_or_create_by_level!(args, 7)
        end
      end
    when "CE2"
      case work_plan_skill.work_plan_domain.domain
      when "Géométrie"
        # [2, 4, 7, 10, 13, 17, 21]
        case count
        when 2...4
          Belt.find_or_create_by_level!(args, 1)
        when 4...7
          Belt.find_or_create_by_level!(args, 2)
        when 7...10
          Belt.find_or_create_by_level!(args, 3)
        when 10...13
          Belt.find_or_create_by_level!(args, 4)
        when 13...17
          Belt.find_or_create_by_level!(args, 5)
        when 17...21
          Belt.find_or_create_by_level!(args, 6)
        when 21
          Belt.find_or_create_by_level!(args, 7)
        end
      when "Grandeurs et Mesures"
        # validation: [3, 7, 11, 15, 19, 23, 28]
        case count
        when 3...7
          Belt.find_or_create_by_level!(args, 1)
        when 7...11
          Belt.find_or_create_by_level!(args, 2)
        when 11...15
          Belt.find_or_create_by_level!(args, 3)
        when 15...19
          Belt.find_or_create_by_level!(args, 4)
        when 19...23
          Belt.find_or_create_by_level!(args, 5)
        when 23...28
          Belt.find_or_create_by_level!(args, 6)
        when 28
          Belt.find_or_create_by_level!(args, 7)
        end
      end
    when "CM1"
      case work_plan_skill.work_plan_domain.domain
      when "Géométrie"
        # [2, 5, 8, 12, 16, 21, 26]
        case count
        when 2...5
          Belt.find_or_create_by_level!(args, 1)
        when 5...8
          Belt.find_or_create_by_level!(args, 2)
        when 8...12
          Belt.find_or_create_by_level!(args, 3)
        when 12...16
          Belt.find_or_create_by_level!(args, 4)
        when 16...21
          Belt.find_or_create_by_level!(args, 5)
        when 21
          Belt.find_or_create_by_level!(args, 6)
        when 26
          Belt.find_or_create_by_level!(args, 7)
        end
      when "Grandeurs et Mesures"
        case count
        # [3, 7, 11, 16, 21, 27, 33]
        when 3...7
          Belt.find_or_create_by_level!(args, 1)
        when 7...11
          Belt.find_or_create_by_level!(args, 2)
        when 11...16
          Belt.find_or_create_by_level!(args, 3)
        when 16...21
          Belt.find_or_create_by_level!(args, 4)
        when 21...27
          Belt.find_or_create_by_level!(args, 5)
        when 27...33
          Belt.find_or_create_by_level!(args, 6)
        when 33
          Belt.find_or_create_by_level!(args, 7)
        end
      end
    end
  end
end
