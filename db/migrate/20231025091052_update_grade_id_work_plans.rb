class UpdateGradeIdWorkPlans < ActiveRecord::Migration[7.0]
  def up
    # classroom
    WorkPlan.all.each do |work_plan|
      p grade_level = work_plan.grade
      p school = work_plan.user.school
      p new_grade = Grade.find_by(grade_level:, school:)
      work_plan.grade_id = new_grade.id
      work_plan.save
      puts "#{work_plan} migration OK"
    end
  end

  def down
    WorkPlan.all.each do |work_plan|
      grade_level = work_plan.grade.grade_level
      work_plan.grade_id = nil
      work_plan.grade = grade_level
      work_plan.save
      p work_plan
    end
  end
end
