# frozen_string_literal: true

class Belt < ApplicationRecord
  BELT_COLORS = %w[blanche jaune orange verte bleue marron noire].freeze
  belongs_to :student

  def completed?
    completed
  end

  # def self.update_or_create_by(args, completed)
  #   obj = self.find_or_create_by(args)
  #   obj.update(completed)
  #   return obj
  # end

  def self.student_last_belt_level(student, domain)
    belt = Belt.where(student: student, domain: domain, completed: true).order(:level).last
    if belt.nil?
      1
    else
      belt.level + 1
    end
  end

  def self.special_newbelt(work_plan_skill, work_plan)
    count = work_plan_skill.work_plan_domain.all_skills_completed_count
    args = {
      student_id: work_plan_skill.student.id,
      domain: work_plan_skill.work_plan_domain.domain,
      grade: work_plan.grade
    }
    Belt.create_new_special_belt(args, count, work_plan_skill)
  end

  def self.find_or_create_by_level!(args, level)
    args.merge!(
      {
        level: level
      }
    )
    belt = Belt.find_or_create_by(args)
    belt.completed = true
    belt.save
  end

  def self.score_to_validate(grade)
    case grade
    when "CE1"
      [
        {
          domain: "Géométrie",
          validation: [2, 4, 7, 10, 13, 17, 21]
        },
        {
          domain: "Grandeurs et Mesures",
          validation: [2, 4, 6, 9, 12, 15, 18]
        }
      ]
    when "CE2"
      [
        {
          domain: "Géométrie",
          validation: [4, 8, 7, 12, 17, 22, 27]
        },
        {
          domain: "Grandeurs et Mesures",
          validation: [5, 10, 15, 20, 25, 30, 35]
        }
      ]
    end
  end

  def self.create_new_special_belt(args, count, work_plan_skill)
    case args[:grade]
    when "CE1"
      case work_plan_skill.work_plan_domain.domain
      when "Géométrie"
        case count
        when 2
          Belt.find_or_create_by_level!(args, 1)
        when 4
          Belt.find_or_create_by_level!(args, 2)
        when 7
          Belt.find_or_create_by_level!(args, 3)
        when 10
          Belt.find_or_create_by_level!(args, 4)
        when 13
          Belt.find_or_create_by_level!(args, 5)
        when 17
          Belt.find_or_create_by_level!(args, 6)
        when 21
          Belt.find_or_create_by_level!(args, 7)
        end
      when "Grandeurs et Mesures"
        case count
        when 2
          Belt.find_or_create_by_level!(args, 1)
        when 4
          Belt.find_or_create_by_level!(args, 2)
        when 5
          Belt.find_or_create_by_level!(args, 3)
        when 9
          Belt.find_or_create_by_level!(args, 4)
        when 12
          Belt.find_or_create_by_level!(args, 5)
        when 15
          Belt.find_or_create_by_level!(args, 6)
        when 18
          Belt.find_or_create_by_level!(args, 7)
        end
      end
    when "CE2"
      case work_plan_skill.work_plan_domain.domain
      when "Géométrie"
        case count
        when 4
          Belt.find_or_create_by_level!(args, 1)
        when 8
          Belt.find_or_create_by_level!(args, 2)
        when 13
          Belt.find_or_create_by_level!(args, 3)
        when 18
          Belt.find_or_create_by_level!(args, 4)
        when 22
          Belt.find_or_create_by_level!(args, 5)
        when 27
          Belt.find_or_create_by_level!(args, 6)
        when 32
          Belt.find_or_create_by_level!(args, 7)
        end
      when "Grandeurs et Mesures"
        case count
        when 5
          Belt.find_or_create_by_level!(args, 1)
        when 10
          Belt.find_or_create_by_level!(args, 2)
        when 15
          Belt.find_or_create_by_level!(args, 3)
        when 20
          Belt.find_or_create_by_level!(args, 4)
        when 25
          Belt.find_or_create_by_level!(args, 5)
        when 30
          Belt.find_or_create_by_level!(args, 6)
        when 35
          Belt.find_or_create_by_level!(args, 7)
        end
      end
    end
  end
end
