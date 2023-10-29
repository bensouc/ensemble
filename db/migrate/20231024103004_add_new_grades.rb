class AddNewGrades < ActiveRecord::Migration[7.0]
  def up
    School.all.each do |school|
      Classroom::GRADE.each do |grade|
        p Grade.create!(grade_level: grade, name: grade, school: school)
      end
    end
  end

  def down
    Grade.destroy_all
  end
end
