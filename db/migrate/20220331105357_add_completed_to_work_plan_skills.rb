class AddCompletedToWorkPlanSkills < ActiveRecord::Migration[6.0]
  def change
    add_column :work_plan_skills, :completed, :boolean, default: false
  end
end
