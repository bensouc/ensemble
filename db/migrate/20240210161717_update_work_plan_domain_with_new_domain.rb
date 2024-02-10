class UpdateWorkPlanDomainWithNewDomain < ActiveRecord::Migration[7.0]
  def change
    rename_column :work_plan_domains, :domain, :name_domain
    add_reference :work_plan_domains, :domain, foreign_key: true


  end
end
