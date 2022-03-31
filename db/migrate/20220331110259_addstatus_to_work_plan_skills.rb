class AddstatusToWorkPlanSkills < ActiveRecord::Migration[6.0]
  def change
    add_column :work_plan_skills, :status, :string, default: 'new'
  end
end
