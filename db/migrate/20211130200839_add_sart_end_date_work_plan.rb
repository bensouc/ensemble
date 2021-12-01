class AddSartEndDateWorkPlan < ActiveRecord::Migration[6.0]
  def change
    add_column :work_plans, :start_date, :date
    add_column :work_plans, :end_date, :date
  end
end
