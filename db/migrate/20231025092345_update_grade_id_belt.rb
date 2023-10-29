class UpdateGradeIdBelt < ActiveRecord::Migration[7.0]
def up
  # classroom
  Belt.all.each do |belt|
    p grade_level = belt.grade
    p school = belt.student.classroom.user.school
    p new_grade = Grade.find_by(grade_level:, school:)
    belt.grade_id = new_grade.id
    belt.save
    puts "#{belt} migration OK"
  end
end

def down
  Belt.all.each do |belt|
    grade_level = belt.grade.grade_level
    belt.grade_id = nil
    belt.grade = grade_level
    belt.save
    p belt
  end
end
end
