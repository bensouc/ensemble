class UpdateGradeIdSKills < ActiveRecord::Migration[7.0]
  def up
    # classroom
    Skill.all.each do |skill|
      grade_level = skill.grade
      school = skill.school
      new_grade = Grade.find_by(grade_level:, school:)
      skill.grade_id = new_grade.id
      skill.save
      p skill
    end
  end

  def down
    Skill.all.each do |skill|
      grade_level = skill.grade.grade_level
      skill.grade_id = nil
      skill.grade = grade_level
      skill.save
      p skill
    end
  end
end
