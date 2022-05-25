class Belt < ApplicationRecord
  BELT_COLORS = %w(blanche jaune orange verte bleue marron noire)
  belongs_to :student

  def completed?
    self.completed
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

    if work_plan_skill.work_plan_domain.domain == "Géométrie"
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
    elsif work_plan_skill.work_plan_domain.domain == "Grandeurs et Mesures"
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
end
