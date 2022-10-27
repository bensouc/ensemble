class RemovekeyforWorkPlanDomain < ActiveRecord::Migration[6.0]
  def change
    remove_reference(:work_plan_domains, :student, index: true)
  end
end
