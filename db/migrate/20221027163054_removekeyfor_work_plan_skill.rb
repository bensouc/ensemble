class RemovekeyforWorkPlanSkill < ActiveRecord::Migration[6.0]
  def change
    # remove_foreign_key :work_plan_skills, column: :shared_user_id
    remove_reference(:work_plan_skills, :student, index: true)
  end
end
