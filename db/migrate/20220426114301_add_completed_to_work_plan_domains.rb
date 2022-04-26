class AddCompletedToWorkPlanDomains < ActiveRecord::Migration[6.0]
  def change
    add_column :work_plan_domains, :completed, :boolean, default: false
  end
end
