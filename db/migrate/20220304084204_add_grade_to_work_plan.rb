class AddGradeToWorkPlan < ActiveRecord::Migration[6.0]
  def change
    add_column :work_plans, :grade, :string
  end
end
