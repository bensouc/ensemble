class AddToWorkPlanSpecialWpsBoolean < ActiveRecord::Migration[6.0]
  def change
    add_column :work_plans, :special_wps, :boolean, default: false
  end
end
