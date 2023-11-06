class AddGradeReferenceToModels < ActiveRecord::Migration[7.0]
  def change
    add_reference :skills, :grade, foreign_key: true
    add_reference :work_plans, :grade, foreign_key: true
    add_reference :belts, :grade, foreign_key: true
    add_reference :classrooms, :grade, foreign_key: true
  end
end
