class AddStudentRefToWorkPlanSkills < ActiveRecord::Migration[6.0]
  def change
    add_reference :work_plan_skills, :student, null: true, foreign_key: true
  end
end
