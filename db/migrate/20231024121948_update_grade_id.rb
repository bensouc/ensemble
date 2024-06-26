class UpdateGradeId < ActiveRecord::Migration[7.0]
  def up
    # classroom
    Classroom.all.each do |classroom|
      p classroom
      p grade_level = classroom.grade
      p school = classroom.user.school
      p new_grade = Grade.find_by(grade_level:, school:)
      # if !new_grade.nil?
        classroom.grade_id = new_grade.id
        classroom.save
        p classroom
      # end
    end
  end

  def down
    Classroom.all.each do |classroom|
      grade_level = classroom.grade
      classroom.grade_id = nil
      classroom.save
      p classroom
    end
  end
end
