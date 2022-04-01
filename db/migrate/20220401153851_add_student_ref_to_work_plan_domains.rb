class AddStudentRefToWorkPlanDomains < ActiveRecord::Migration[6.0]
  def change
    add_reference :work_plan_domains, :student, null: true, foreign_key: true
  end
end
